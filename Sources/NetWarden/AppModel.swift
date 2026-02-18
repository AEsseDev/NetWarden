import Foundation
import Combine
import AppKit

@MainActor
final class AppModel: ObservableObject {
    @Published var isGamingModeEnabled = false
    @Published var isAutoGamingModeEnabled = UserDefaults.standard.bool(forKey: "autoGamingModeEnabled")
    @Published var usages: [ProcessUsage] = []
    @Published var rules: [ProcessRule] = []
    @Published var actionLogs: [ActionLog] = []
    @Published var recommendations: [RecommendationItem] = []
    @Published var newRuleName = ""
    @Published var newRuleAction: RuleAction = .pause
    @Published var uiNotice = ""
    @Published var logLevelFilter: LogViewFilter = .info
    @Published var logPreviewLines: [String] = []

    private let monitor = NetworkMonitorService()
    private let control = ProcessControlService()
    private let store = RulesStore()
    private var logTimer: Timer?
    private var autoManagedGamingMode = false

    func start() {
        AppLogger.shared.info("app-model", "Старт AppModel")
        if let recoveryNotice = control.recoverIfNeeded() {
            uiNotice = recoveryNotice
            AppLogger.shared.warning("app-model", recoveryNotice)
        }
        loadRules()
        monitor.onSnapshot = { [weak self] data in
            Task { @MainActor in
                self?.usages = data
                self?.recommendations = self?.buildRecommendations(from: data) ?? []
                self?.handleAutoGamingMode(using: data)
            }
        }
        control.onAction = { [weak self] log in
            Task { @MainActor in
                self?.actionLogs.insert(log, at: 0)
                self?.actionLogs = Array(self?.actionLogs.prefix(100) ?? [])
            }
        }
        monitor.start()
        control.updateRules(rules)
        refreshLogPreview()
        startLogTimer()
    }

    func stop() {
        AppLogger.shared.info("app-model", "Остановка AppModel")
        monitor.stop()
        control.setEnabled(false)
        stopLogTimer()
    }

    func setGamingMode(_ enabled: Bool) {
        AppLogger.shared.info("app-model", "Переключение игрового режима: \(enabled ? "ВКЛ" : "ВЫКЛ")")
        isGamingModeEnabled = enabled
        control.setEnabled(enabled)
    }


    func setAutoGamingMode(_ enabled: Bool) {
        isAutoGamingModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "autoGamingModeEnabled")

        if !enabled, autoManagedGamingMode {
            setGamingMode(false)
            autoManagedGamingMode = false
        }

        let state = enabled ? "ВКЛ" : "ВЫКЛ"
        uiNotice = "Авто-игровой режим: \(state)"
        AppLogger.shared.info("app-model", "Авто-игровой режим: \(state)")
    }

    func addRule() {
        let name = newRuleName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if ProcessCatalog.isProtected(name) {
            uiNotice = "Защищенный процесс. Riot/League/Vanguard нельзя гасить автоматически."
            AppLogger.shared.warning("app-model", "Попытка добавить защищенный процесс в правила: \(name)")
            return
        }
        guard !rules.contains(where: { $0.processName.caseInsensitiveCompare(name) == .orderedSame }) else { return }
        rules.append(ProcessRule(processName: name, action: newRuleAction, isEnabled: true, isDefault: false))
        newRuleName = ""
        uiNotice = "Правило добавлено: \(name)"
        AppLogger.shared.info("app-model", "Добавлено правило: \(name), action=\(newRuleAction.rawValue)")
        persistRules()
    }

    func removeRule(_ rule: ProcessRule) {
        guard !rule.isDefault else { return }
        rules.removeAll { $0.id == rule.id }
        uiNotice = "Правило удалено: \(rule.processName)"
        AppLogger.shared.info("app-model", "Удалено правило: \(rule.processName)")
        persistRules()
    }

    func toggleRule(_ rule: ProcessRule, enabled: Bool) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        rules[idx].isEnabled = enabled
        uiNotice = enabled ? "Правило включено: \(rule.processName)" : "Правило выключено: \(rule.processName)"
        AppLogger.shared.info("app-model", "Переключено правило: \(rule.processName) -> \(enabled)")
        persistRules()
    }

    func setRuleAction(_ rule: ProcessRule, action: RuleAction) {
        guard let idx = rules.firstIndex(where: { $0.id == rule.id }) else { return }
        if ProcessCatalog.isProtected(rule.processName), action == .terminate {
            uiNotice = "Для защищенного процесса нельзя выбрать «Завершить»."
            AppLogger.shared.warning("app-model", "Запрет terminate для защищенного процесса: \(rule.processName)")
            return
        }
        rules[idx].action = action
        uiNotice = "Действие обновлено для \(rule.processName): \(action.title)"
        AppLogger.shared.info("app-model", "Обновлено действие правила: \(rule.processName) -> \(action.rawValue)")
        persistRules()
    }

    func description(for process: String) -> String {
        ProcessCatalog.description(for: process)
    }

    func openLogFile() {
        let path = AppLogger.shared.logPath
        let url = URL(fileURLWithPath: path)
        NSWorkspace.shared.open(url)
        AppLogger.shared.info("app-model", "Открыт лог-файл: \(path)")
    }

    func setLogFilter(_ filter: LogViewFilter) {
        logLevelFilter = filter
        AppLogger.shared.info("app-model", "Изменен фильтр лога: \(filter.title)")
        refreshLogPreview()
    }

    func refreshLogPreview() {
        let path = AppLogger.shared.logPath
        guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
            logPreviewLines = []
            return
        }

        let filtered = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .map(String.init)
            .filter { $0.contains(logLevelFilter.token) }

        logPreviewLines = Array(filtered.suffix(120))
    }

    private func loadRules() {
        if let loaded = store.loadRules(), !loaded.isEmpty {
            rules = loaded
            AppLogger.shared.info("app-model", "Загружены пользовательские правила: \(rules.count)")
        } else {
            rules = ProcessCatalog.defaultRules
            store.saveRules(rules)
            AppLogger.shared.info("app-model", "Загружены базовые правила: \(rules.count)")
        }
    }

    private func persistRules() {
        store.saveRules(rules)
        control.updateRules(rules)
        AppLogger.shared.debug("app-model", "persistRules, count=\(rules.count)")
    }

    private func startLogTimer() {
        stopLogTimer()
        logTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshLogPreview()
            }
        }
    }

    private func stopLogTimer() {
        logTimer?.invalidate()
        logTimer = nil
    }

    private func handleAutoGamingMode(using usages: [ProcessUsage]) {
        guard isAutoGamingModeEnabled else { return }

        let hasRunningGame = usages.contains { ProcessCatalog.isGameProcess($0.processName) }

        if hasRunningGame, !isGamingModeEnabled {
            setGamingMode(true)
            autoManagedGamingMode = true
            uiNotice = "Обнаружена игра: игровой режим включен автоматически."
            AppLogger.shared.info("app-model", "Авто-режим: игра обнаружена, включаем игровой режим")
        } else if !hasRunningGame, autoManagedGamingMode {
            setGamingMode(false)
            autoManagedGamingMode = false
            uiNotice = "Игра закрыта: игровой режим выключен автоматически."
            AppLogger.shared.info("app-model", "Авто-режим: игра не обнаружена, выключаем игровой режим")
        }
    }

    private func buildRecommendations(from usages: [ProcessUsage]) -> [RecommendationItem] {
        let top = usages.prefix(8)
        return top.map { usage in
            let p = usage.processName
            if ProcessCatalog.isProtected(p) {
                return RecommendationItem(processName: p, reason: "Защищенный игровой/безопасностный процесс.", note: "Никогда не убивайте его автоматически. Он нужен для корректной работы игры.")
            }
            if rules.contains(where: { $0.processName.caseInsensitiveCompare(p) == .orderedSame }) {
                return RecommendationItem(processName: p, reason: "Уже контролируется вашими правилами.", note: ProcessCatalog.description(for: p))
            }

            if usage.totalPerSecond > 300_000 {
                return RecommendationItem(processName: p, reason: "Высокий сетевой трафик прямо сейчас. Стоит добавить в авто-контроль.", note: ProcessCatalog.description(for: p))
            }

            return RecommendationItem(processName: p, reason: "Средняя активность. Наблюдайте во время матча.", note: ProcessCatalog.description(for: p))
        }
    }
}
