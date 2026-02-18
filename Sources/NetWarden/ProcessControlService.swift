import Foundation

private struct WatchdogState: Codable {
    var enabled: Bool
    var pausedProcesses: [String]
}

final class ProcessControlService {
    var onAction: ((ActionLog) -> Void)?

    private let queue = DispatchQueue(label: "netwarden.control.watchdog", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var isEnabled = false
    private var rules: [ProcessRule] = []
    private var throttleManager = SystemThrottleManager()
    private var coolDown: [String: Date] = [:]
    private var pausedByApp: Set<String> = []
    private let stateFileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NetWarden", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        stateFileURL = dir.appendingPathComponent("watchdog-state.json")
        loadState()
    }

    func recoverIfNeeded() -> String? {
        guard let state = readState(), state.enabled || !state.pausedProcesses.isEmpty else {
            return nil
        }

        AppLogger.shared.warning("watchdog", "Обнаружено незавершенное состояние watchdog, запускаю аварийный recovery")
        throttleManager.disable()

        for process in state.pausedProcesses {
            _ = Shell.runIgnoringFailure("pkill -CONT -x '\(process)'", category: "watchdog")
            AppLogger.shared.info("watchdog", "Recovery: возобновлен процесс: \(process)")
        }

        pausedByApp.removeAll()
        isEnabled = false
        clearState()
        return "После прошлого запуска найдено аварийное состояние. Процессы и настройки восстановлены."
    }

    func setEnabled(_ enabled: Bool) {
        if enabled == isEnabled { return }
        isEnabled = enabled
        AppLogger.shared.info("watchdog", "Игровой режим -> \(enabled ? "ВКЛ" : "ВЫКЛ")")

        if enabled {
            throttleManager.enable()
            startWatchdog()
            persistState()
        } else {
            stopWatchdog()
            throttleManager.disable()
            resumePausedTracked()
            pausedByApp.removeAll()
            clearState()
        }
    }

    func updateRules(_ rules: [ProcessRule]) {
        self.rules = rules
        AppLogger.shared.info("watchdog", "Обновлены правила: \(rules.count)")
    }

    private func startWatchdog() {
        guard timer == nil else { return }
        AppLogger.shared.info("watchdog", "Старт watchdog")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in self?.enforce() }
        timer.resume()
        self.timer = timer
    }

    private func stopWatchdog() {
        timer?.cancel()
        timer = nil
        AppLogger.shared.info("watchdog", "Остановка watchdog")
    }

    private func enforce() {
        let activeRules = rules.filter { $0.isEnabled }
        for rule in activeRules {
            if ProcessCatalog.isProtected(rule.processName) { continue }
            guard isProcessRunning(rule.processName) else { continue }
            guard allowByCooldown(process: rule.processName, action: rule.action) else { continue }

            let command: String
            switch rule.action {
            case .pause:
                command = "pkill -STOP -x '\(rule.processName)'"
            case .terminate:
                command = "pkill -TERM -x '\(rule.processName)'"
            }

            let output = Shell.runIgnoringFailure(command, category: "watchdog")
            let result = output.trimmingCharacters(in: .whitespacesAndNewlines)
            let status = result.isEmpty ? "applied" : result

            if rule.action == .pause {
                pausedByApp.insert(rule.processName)
                persistState()
            }

            AppLogger.shared.warning("watchdog", "Действие: \(rule.processName) -> \(rule.action.rawValue), результат=\(status)")
            onAction?(ActionLog(date: Date(), processName: rule.processName, action: rule.action, result: status))
        }
    }

    private func isProcessRunning(_ name: String) -> Bool {
        !Shell.runIgnoringFailure("pgrep -x '\(name)'", category: "watchdog").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func allowByCooldown(process: String, action: RuleAction) -> Bool {
        let key = "\(process):\(action.rawValue)"
        let now = Date()
        if let prev = coolDown[key], now.timeIntervalSince(prev) < 3 {
            return false
        }
        coolDown[key] = now
        return true
    }

    private func resumePausedTracked() {
        for process in pausedByApp {
            _ = Shell.runIgnoringFailure("pkill -CONT -x '\(process)'", category: "watchdog")
            AppLogger.shared.info("watchdog", "Возобновлен процесс: \(process)")
        }
    }

    private func persistState() {
        let state = WatchdogState(enabled: isEnabled, pausedProcesses: Array(pausedByApp).sorted())
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateFileURL, options: .atomic)
    }

    private func readState() -> WatchdogState? {
        guard let data = try? Data(contentsOf: stateFileURL) else { return nil }
        return try? JSONDecoder().decode(WatchdogState.self, from: data)
    }

    private func loadState() {
        guard let state = readState() else { return }
        isEnabled = state.enabled
        pausedByApp = Set(state.pausedProcesses)
        AppLogger.shared.info("watchdog", "Загружено состояние watchdog: enabled=\(state.enabled), paused=\(state.pausedProcesses.count)")
    }

    private func clearState() {
        try? FileManager.default.removeItem(at: stateFileURL)
    }
}
