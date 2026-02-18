import Foundation

enum ShellError: Error {
    case launchFailed(String)
    case commandFailed(String, Int32, String)
}

enum Shell {
    static func run(_ command: String, category: String = "shell") throws -> String {
        let started = Date()
        AppLogger.shared.debug(category, "run: \(command)")
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-lc", command]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
        } catch {
            AppLogger.shared.error(category, "launch failed: \(command)")
            throw ShellError.launchFailed(command)
        }

        process.waitUntilExit()

        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            let duration = Date().timeIntervalSince(started)
            AppLogger.shared.error(category, "failed (\(process.terminationStatus), \(String(format: "%.2fs", duration))): \(command) :: \(stderr.trimmingCharacters(in: .whitespacesAndNewlines))")
            throw ShellError.commandFailed(command, process.terminationStatus, stderr.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let duration = Date().timeIntervalSince(started)
        AppLogger.shared.debug(category, "ok (\(String(format: "%.2fs", duration))): \(command)")
        return output
    }

    static func runIgnoringFailure(_ command: String, category: String = "shell") -> String {
        (try? run(command, category: category)) ?? ""
    }
}
