import Foundation

final class NetworkMonitorService {
    var onSnapshot: (([ProcessUsage]) -> Void)?

    private let queue = DispatchQueue(label: "netwarden.network.monitor", qos: .userInitiated)
    private var timer: DispatchSourceTimer?
    private var previousTotals: [Int: (in: Double, out: Double)] = [:]
    private var lastDate = Date()
    private var sampleCount = 0

    func start() {
        guard timer == nil else { return }
        AppLogger.shared.info("monitor", "Запуск мониторинга сети")
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now(), repeating: .seconds(2))
        timer.setEventHandler { [weak self] in
            self?.collect()
        }
        timer.resume()
        self.timer = timer
    }

    func stop() {
        timer?.cancel()
        timer = nil
        AppLogger.shared.info("monitor", "Остановка мониторинга сети")
    }

    private func collect() {
        let raw = Shell.runIgnoringFailure("nettop -P -L 1 -n -x 2>/dev/null", category: "monitor")
        let now = Date()
        let delta = max(1.0, now.timeIntervalSince(lastDate))
        lastDate = now

        let parsed = parse(raw: raw)
        let withRates: [ProcessUsage] = parsed.compactMap { tuple in
            let prev = previousTotals[tuple.pid] ?? (0, 0)
            let inRate = max(0, tuple.bytesIn - prev.in) / delta
            let outRate = max(0, tuple.bytesOut - prev.out) / delta
            previousTotals[tuple.pid] = (tuple.bytesIn, tuple.bytesOut)

            guard inRate + outRate > 64 else { return nil }
            return ProcessUsage(pid: tuple.pid, processName: tuple.process, bytesInPerSecond: inRate, bytesOutPerSecond: outRate, timestamp: now)
        }
        .sorted { $0.totalPerSecond > $1.totalPerSecond }

        sampleCount += 1
        if sampleCount % 5 == 0 {
            let top = withRates.prefix(3).map { "\($0.processName):\(Int($0.totalPerSecond))B/s" }.joined(separator: ", ")
            AppLogger.shared.debug("monitor", "снимок=\(sampleCount), активных=\(withRates.count), top=[\(top)]")
        }
        onSnapshot?(withRates)
    }

    private func parse(raw: String) -> [(pid: Int, process: String, bytesIn: Double, bytesOut: Double)] {
        var results: [(Int, String, Double, Double)] = []

        for line in raw.split(separator: "\n") {
            let text = String(line)
            if text.hasPrefix("time,") { continue }

            let cols = text.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
            guard cols.count > 5 else { continue }

            let procField = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !procField.isEmpty else { continue }

            let bytesIn = Double(cols[4]) ?? 0
            let bytesOut = Double(cols[5]) ?? 0
            guard bytesIn > 0 || bytesOut > 0 else { continue }

            let (name, pid) = splitProcess(procField)
            guard pid > 0 else { continue }
            results.append((pid, name, bytesIn, bytesOut))
        }

        return results
    }

    private func splitProcess(_ input: String) -> (String, Int) {
        guard let lastDot = input.lastIndex(of: ".") else { return (input, -1) }
        let name = String(input[..<lastDot]).trimmingCharacters(in: .whitespacesAndNewlines)
        let pidRaw = String(input[input.index(after: lastDot)...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return (name, Int(pidRaw) ?? -1)
    }
}
