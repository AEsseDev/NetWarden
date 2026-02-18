import Foundation

enum ProcessCatalog {
    static let defaultRules: [ProcessRule] = [
        ProcessRule(processName: "appstoreagent", action: .pause, isEnabled: true, isDefault: true),
        ProcessRule(processName: "storedownloadd", action: .pause, isEnabled: true, isDefault: true),
        ProcessRule(processName: "nsurlsessiond", action: .pause, isEnabled: true, isDefault: true),
        ProcessRule(processName: "cloudd", action: .pause, isEnabled: true, isDefault: true),
        ProcessRule(processName: "bird", action: .pause, isEnabled: true, isDefault: true),
        ProcessRule(processName: "photolibraryd", action: .pause, isEnabled: true, isDefault: true),
        ProcessRule(processName: "mobileassetd", action: .pause, isEnabled: true, isDefault: true)
    ]

    static let descriptions: [String: String] = [
        "appstoreagent": "Обновления и загрузки App Store.",
        "storedownloadd": "Системный загрузчик обновлений и контента.",
        "nsurlsessiond": "Фоновые сетевые загрузки приложений через URLSession.",
        "cloudd": "Служба синхронизации iCloud.",
        "bird": "Демон синхронизации файлов iCloud Drive.",
        "photolibraryd": "Синхронизация и индексация медиатеки Фото.",
        "mobileassetd": "Загрузка системных ассетов и пакетов данных Apple.",
        "softwareupdated": "Служба системных обновлений macOS.",
        "RiotClientService": "Служба лаунчера Riot.",
        "LeagueClient": "Основной процесс клиента League of Legends.",
        "LeagueClientUx": "Процесс интерфейса клиента League of Legends."
    ]

    static let protectedExactNames: Set<String> = [
        "RiotClientServices",
        "RiotClientService",
        "Riot Client",
        "LeagueClient",
        "LeagueClientUx",
        "LeagueClientUx Helper",
        "League of Legends",
        "vgc",
        "vgk"
    ]

    static let protectedNameTokens: [String] = [
        "riot",
        "league",
        "vanguard",
        "valorant",
        "vgc",
        "vgk"
    ]

    static func description(for process: String) -> String {
        descriptions[process] ?? "Локального описания пока нет. Наблюдайте за процессом и решайте вручную."
    }

    static func isProtected(_ process: String) -> Bool {
        if protectedExactNames.contains(process) { return true }
        let lower = process.lowercased()
        return protectedNameTokens.contains(where: { lower.contains($0) })
    }
}
