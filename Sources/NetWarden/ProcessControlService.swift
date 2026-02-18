import Foundation

final class ProcessControlService {
    var onAction: ((ActionLog) -> Void)?

    private let queue = DispatchQueue(label: "netwarden.control.watchdog", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var isEnabled = false
    private var rules: [ProcessRule] = []
    private var throttleManager = SystemThrottleManager()
    private var coolDown: [String: Date] = [:]

    func setEnabled(_ enabled: Bool) {
        if enabled == isEnabled { return }
        isEnabled = enabled
        AppLogger.shared.info("watchdog", "Игровой режим -> \(enabled ? "ВКЛ" : "ВЫКЛ")")
        if enabled {
            throttleManager.enable()
            startWatchdog()
        } else {
            stopWatchdog()
            throttleManager.disable()
            resumePaused()
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

    private func resumePaused() {
        for rule in rules where rule.isEnabled && rule.action == .pause {
            _ = Shell.runIgnoringFailure("pkill -CONT -x '\(rule.processName)'", category: "watchdog")
            AppLogger.shared.info("watchdog", "Возобновлен процесс: \(rule.processName)")
        }
    }
}
