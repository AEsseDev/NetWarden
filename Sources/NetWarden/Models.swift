import Foundation

enum RuleAction: String, Codable, CaseIterable, Identifiable {
    case pause
    case terminate

    var id: String { rawValue }
    var title: String {
        switch self {
        case .pause: return "Пауза"
        case .terminate: return "Завершить"
        }
    }
}

enum LogViewFilter: String, CaseIterable, Identifiable {
    case info
    case debug
    case warning
    case error

    var id: String { rawValue }

    var title: String {
        switch self {
        case .info: return "INFO"
        case .debug: return "DEBUG"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }

    var token: String {
        "[\(title)]"
    }
}

struct ProcessRule: Codable, Identifiable, Hashable {
    let id: UUID
    var processName: String
    var action: RuleAction
    var isEnabled: Bool
    var isDefault: Bool

    init(id: UUID = UUID(), processName: String, action: RuleAction, isEnabled: Bool = true, isDefault: Bool = false) {
        self.id = id
        self.processName = processName
        self.action = action
        self.isEnabled = isEnabled
        self.isDefault = isDefault
    }
}

struct ProcessUsage: Identifiable, Hashable {
    let pid: Int
    let processName: String
    let bytesInPerSecond: Double
    let bytesOutPerSecond: Double
    let timestamp: Date

    var id: String { "\(processName)-\(pid)" }
    var totalPerSecond: Double { bytesInPerSecond + bytesOutPerSecond }
}

struct RecommendationItem: Identifiable, Hashable {
    let id = UUID()
    let processName: String
    let reason: String
    let note: String
}

struct ActionLog: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let processName: String
    let action: RuleAction
    let result: String
}
