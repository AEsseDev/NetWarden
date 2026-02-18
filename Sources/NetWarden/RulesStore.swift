import Foundation

final class RulesStore {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("NetWarden", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("rules.json")
        AppLogger.shared.info("rules", "Хранилище правил: \(fileURL.path)")
    }

    func loadRules() -> [ProcessRule]? {
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        let decoded = try? JSONDecoder().decode([ProcessRule].self, from: data)
        AppLogger.shared.info("rules", "Загружено правил: \(decoded?.count ?? 0)")
        return decoded
    }

    func saveRules(_ rules: [ProcessRule]) {
        guard let data = try? JSONEncoder().encode(rules) else { return }
        try? data.write(to: fileURL, options: .atomic)
        AppLogger.shared.info("rules", "Сохранено правил: \(rules.count)")
    }
}
