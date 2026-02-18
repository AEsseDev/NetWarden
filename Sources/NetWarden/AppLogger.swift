import Foundation
import OSLog

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARN"
    case error = "ERROR"
}

final class AppLogger: @unchecked Sendable {
    static let shared = AppLogger()

    private let subsystem = "com.antonesse.netwarden"
    private let osLogger: Logger
    private let queue = DispatchQueue(label: "netwarden.logger", qos: .utility)
    private let fileURL: URL

    private init() {
        osLogger = Logger(subsystem: subsystem, category: "app")

        let logsDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("NetWarden", isDirectory: true)

        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        fileURL = logsDir.appendingPathComponent("netwarden.log")
        rotateIfNeeded(maxBytes: 5_000_000, keep: 3)

        info("logger", "Логгер инициализирован. Файл: \(fileURL.path)")
    }

    var logPath: String { fileURL.path }

    func debug(_ category: String, _ message: String) {
        write(level: .debug, category: category, message: message)
    }

    func info(_ category: String, _ message: String) {
        write(level: .info, category: category, message: message)
    }

    func warning(_ category: String, _ message: String) {
        write(level: .warning, category: category, message: message)
    }

    func error(_ category: String, _ message: String) {
        write(level: .error, category: category, message: message)
    }

    private func write(level: LogLevel, category: String, message: String) {
        let trimmed = message.replacingOccurrences(of: "\n", with: " ")
        let line = "\(timestamp()) [\(level.rawValue)] [\(category)] \(trimmed)"

        switch level {
        case .debug:
            osLogger.debug("\(line, privacy: .public)")
        case .info:
            osLogger.info("\(line, privacy: .public)")
        case .warning:
            osLogger.warning("\(line, privacy: .public)")
        case .error:
            osLogger.error("\(line, privacy: .public)")
        }

        queue.async { [fileURL] in
            let data = (line + "\n").data(using: .utf8) ?? Data()
            if FileManager.default.fileExists(atPath: fileURL.path) {
                if let handle = try? FileHandle(forWritingTo: fileURL) {
                    defer { try? handle.close() }
                    _ = try? handle.seekToEnd()
                    try? handle.write(contentsOf: data)
                }
            } else {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    private func timestamp() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: Date())
    }

    private func rotateIfNeeded(maxBytes: Int, keep: Int) {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let size = attrs[.size] as? NSNumber,
              size.intValue >= maxBytes else { return }

        for idx in stride(from: keep - 1, through: 1, by: -1) {
            let oldURL = fileURL.deletingPathExtension().appendingPathExtension("log.\(idx)")
            let newURL = fileURL.deletingPathExtension().appendingPathExtension("log.\(idx + 1)")
            if FileManager.default.fileExists(atPath: newURL.path) {
                try? FileManager.default.removeItem(at: newURL)
            }
            if FileManager.default.fileExists(atPath: oldURL.path) {
                try? FileManager.default.moveItem(at: oldURL, to: newURL)
            }
        }

        let firstBackup = fileURL.deletingPathExtension().appendingPathExtension("log.1")
        if FileManager.default.fileExists(atPath: firstBackup.path) {
            try? FileManager.default.removeItem(at: firstBackup)
        }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try? FileManager.default.moveItem(at: fileURL, to: firstBackup)
        }
    }
}
