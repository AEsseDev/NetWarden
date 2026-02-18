import SwiftUI

struct PopoverView: View {
    @ObservedObject var model: AppModel
    let onOpenDashboard: () -> Void
    let onQuit: () -> Void

    var body: some View {
        ZStack {
            CyberBackground()

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("NETWARDEN")
                        .font(.system(size: 19, weight: .black, design: .rounded))
                        .foregroundStyle(.cyan)
                    Spacer()
                    PulseIndicator(active: model.isGamingModeEnabled)
                    Toggle("", isOn: Binding(
                        get: { model.isGamingModeEnabled },
                        set: { model.setGamingMode($0) }
                    ))
                    .toggleStyle(.switch)
                }

                Text(model.isGamingModeEnabled ? "Игровой режим: ВКЛ" : "Игровой режим: ВЫКЛ")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(model.isGamingModeEnabled ? .green : .orange)

                NeonCard(title: "Кто сейчас ест интернет") {
                    VStack(spacing: 8) {
                        ForEach(Array(model.usages.prefix(4)), id: \.id) { usage in
                            HStack {
                                Text("\(usage.processName) [\(usage.pid)]")
                                    .lineLimit(1)
                                Spacer()
                                Text(formatRate(usage.totalPerSecond))
                                    .foregroundStyle(.mint)
                            }
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                        }

                        if model.usages.isEmpty {
                            Text("Пока не обнаружено значимого трафика")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(.white.opacity(0.65))
                        }
                    }
                }

                if !model.uiNotice.isEmpty {
                    Text(model.uiNotice)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.cyan.opacity(0.2), in: Capsule())
                }

                HStack(spacing: 10) {
                    Button("Открыть панель", action: onOpenDashboard)
                        .buttonStyle(.borderedProminent)
                    Button("Выход", action: onQuit)
                        .buttonStyle(.bordered)
                }
            }
            .padding(14)
        }
        .frame(width: 360, height: 380)
    }

    private func formatRate(_ value: Double) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary) + "/s"
    }
}

private struct PulseIndicator: View {
    let active: Bool

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let pulse = 0.6 + abs(sin(t * 2.6)) * 0.8
            ZStack {
                Circle()
                    .fill((active ? Color.green : Color.orange).opacity(0.18))
                    .frame(width: 18 + pulse * 10, height: 18 + pulse * 10)
                Circle()
                    .fill(active ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(width: 28, height: 28)
    }
}
