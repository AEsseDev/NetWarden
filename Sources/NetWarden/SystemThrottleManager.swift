import Foundation

final class SystemThrottleManager {
    private let stateDir: URL
    private let stateFile: URL
    private let keys: [(String, String)] = [
        ("com.apple.commerce", "AutoUpdate"),
        ("com.apple.commerce", "AutoUpdateRestartRequired"),
        ("com.apple.SoftwareUpdate", "AutomaticCheckEnabled"),
        ("com.apple.SoftwareUpdate", "AutomaticDownload"),
        ("com.apple.SoftwareUpdate", "ConfigDataInstall"),
        ("com.apple.SoftwareUpdate", "CriticalUpdateInstall")
    ]

    init() {
        let root = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".local", isDirectory: true)
            .appendingPathComponent("state", isDirectory: true)
            .appendingPathComponent("netwarden", isDirectory: true)
        stateDir = root
        stateFile = root.appendingPathComponent("defaults-backup.json")
        try? FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    func enable() {
        AppLogger.shared.info("throttle", "Применение системных ограничений обновлений")
        var backup: [String: String] = [:]
        for (domain, key) in keys {
            let lookup = "defaults read \(domain) \(key)"
            let value = Shell.runIgnoringFailure(lookup, category: "throttle").trimmingCharacters(in: .whitespacesAndNewlines)
            backup["\(domain)::\(key)"] = value.isEmpty ? "__MISSING__" : value
        }

        if let data = try? JSONEncoder().encode(backup) {
            try? data.write(to: stateFile, options: .atomic)
            AppLogger.shared.info("throttle", "Сохранен backup настроек: \(stateFile.path)")
        }

        _ = Shell.runIgnoringFailure("defaults write com.apple.commerce AutoUpdate -bool false", category: "throttle")
        _ = Shell.runIgnoringFailure("defaults write com.apple.commerce AutoUpdateRestartRequired -bool false", category: "throttle")
        _ = Shell.runIgnoringFailure("defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false", category: "throttle")
        _ = Shell.runIgnoringFailure("defaults write com.apple.SoftwareUpdate AutomaticDownload -bool false", category: "throttle")
        _ = Shell.runIgnoringFailure("defaults write com.apple.SoftwareUpdate ConfigDataInstall -bool false", category: "throttle")
        _ = Shell.runIgnoringFailure("defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool false", category: "throttle")
    }

    func disable() {
        AppLogger.shared.info("throttle", "Восстановление системных ограничений обновлений")
        guard let data = try? Data(contentsOf: stateFile),
              let backup = try? JSONDecoder().decode([String: String].self, from: data) else {
            AppLogger.shared.warning("throttle", "backup не найден: \(stateFile.path)")
            return
        }

        for (composite, value) in backup {
            let pieces = composite.components(separatedBy: "::")
            guard pieces.count == 2 else { continue }
            let domain = pieces[0]
            let key = pieces[1]

            if value == "__MISSING__" {
                _ = Shell.runIgnoringFailure("defaults delete '\(domain)' '\(key)'", category: "throttle")
            } else if value == "1" || value == "0" || value == "true" || value == "false" {
                let boolValue = (value == "1" || value == "true") ? "true" : "false"
                _ = Shell.runIgnoringFailure("defaults write '\(domain)' '\(key)' -bool \(boolValue)", category: "throttle")
            } else {
                _ = Shell.runIgnoringFailure("defaults write '\(domain)' '\(key)' '\(value)'", category: "throttle")
            }
        }

        try? FileManager.default.removeItem(at: stateFile)
        AppLogger.shared.info("throttle", "backup удален: \(stateFile.path)")
    }
}
