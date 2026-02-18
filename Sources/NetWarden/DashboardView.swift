import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ZStack {
            CyberBackground()

            VStack(spacing: 14) {
                header

                HStack(spacing: 14) {
                    trafficPanel
                    recommendationsPanel
                }

                HStack(spacing: 14) {
                    rulesPanel
                    actionsPanel
                }
            }
            .padding(18)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("Панель управления NetWarden")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(.cyan)
                Text("Агрессивный watchdog. Процессы Riot/League/Vanguard защищены.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            Spacer()
            PulseHeader(active: model.isGamingModeEnabled)
            Toggle("Игровой режим", isOn: Binding(
                get: { model.isGamingModeEnabled },
                set: { model.setGamingMode($0) }
            ))
            .toggleStyle(.switch)
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .tint(model.isGamingModeEnabled ? .green : .orange)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.28), lineWidth: 1))
        )
        .shadow(color: .cyan.opacity(0.18), radius: 12)
    }

    private var trafficPanel: some View {
        NeonCard(title: "Текущие потребители сети") {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(model.usages, id: \.id) { usage in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(usage.processName) [\(usage.pid)]")
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white)
                                if ProcessCatalog.isProtected(usage.processName) {
                                    Text("ЗАЩИЩЕНО")
                                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.green.opacity(0.2), in: Capsule())
                                        .foregroundStyle(.green)
                                }
                                Spacer()
                                Text(formatRate(usage.totalPerSecond))
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.mint)
                            }
                            Text(model.description(for: usage.processName))
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                        .padding(10)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var recommendationsPanel: some View {
        NeonCard(title: "Рекомендации") {
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(model.recommendations) { item in
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.processName)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundStyle(.cyan)
                            Text(item.reason)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                            Text(item.note)
                                .font(.system(size: 11, weight: .regular, design: .rounded))
                                .foregroundStyle(.white.opacity(0.72))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var rulesPanel: some View {
        NeonCard(title: "Правила авто-контроля") {
            VStack(spacing: 10) {
                HStack {
                    TextField("имя процесса, например Discord", text: $model.newRuleName)
                        .textFieldStyle(.roundedBorder)
                    Picker("Действие", selection: $model.newRuleAction) {
                        ForEach(RuleAction.allCases) { action in
                            Text(action.title).tag(action)
                        }
                    }
                    .frame(width: 120)
                    Button("Добавить") { model.addRule() }
                        .buttonStyle(.borderedProminent)
                }

                if !model.uiNotice.isEmpty {
                    Text(model.uiNotice)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.cyan.opacity(0.2), in: Capsule())
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(model.rules) { rule in
                            HStack {
                                Toggle("", isOn: Binding(
                                    get: { rule.isEnabled },
                                    set: { model.toggleRule(rule, enabled: $0) }
                                ))
                                .toggleStyle(.switch)
                                .frame(width: 40)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(rule.processName)
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(.white)
                                        if rule.isDefault {
                                            Text("БАЗОВОЕ")
                                                .font(.system(size: 9, weight: .black, design: .rounded))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.cyan.opacity(0.2), in: Capsule())
                                                .foregroundStyle(.cyan)
                                        }
                                        if ProcessCatalog.isProtected(rule.processName) {
                                            Text("ЗАЩИЩЕНО")
                                                .font(.system(size: 9, weight: .black, design: .rounded))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.green.opacity(0.2), in: Capsule())
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    Text(model.description(for: rule.processName))
                                        .font(.system(size: 10, weight: .regular, design: .rounded))
                                        .foregroundStyle(.white.opacity(0.68))
                                }

                                Spacer()

                                Picker("", selection: Binding(
                                    get: { rule.action },
                                    set: { model.setRuleAction(rule, action: $0) }
                                )) {
                                    ForEach(RuleAction.allCases) { action in
                                        Text(action.title).tag(action)
                                    }
                                }
                                .frame(width: 110)

                                if !rule.isDefault {
                                    Button(role: .destructive) {
                                        model.removeRule(rule)
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                            .padding(8)
                            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var actionsPanel: some View {
        NeonCard(title: "Действия watchdog") {
            VStack(spacing: 10) {
                HStack {
                    Button("Открыть лог") {
                        model.openLogFile()
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()

                    Picker("Уровень", selection: Binding(
                        get: { model.logLevelFilter },
                        set: { model.setLogFilter($0) }
                    )) {
                        ForEach(LogViewFilter.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 280)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(model.actionLogs) { log in
                            HStack(alignment: .top) {
                                Circle()
                                    .fill(log.action == .pause ? Color.orange : Color.red)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 5)

                                VStack(alignment: .leading, spacing: 3) {
                                    Text("\(log.processName) -> \(log.action.title)")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundStyle(.white)
                                    Text(shortDate(log.date))
                                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                                        .foregroundStyle(.white.opacity(0.62))
                                }
                                Spacer()
                            }
                            .padding(8)
                            .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }

                Divider().overlay(.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Лог (\(model.logLevelFilter.title))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.9))

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(model.logPreviewLines.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.88))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .frame(minHeight: 130)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func formatRate(_ value: Double) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(value), countStyle: .binary) + "/s"
    }

    private func shortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: date)
    }
}

private struct PulseHeader: View {
    let active: Bool

    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let scale = 0.9 + abs(sin(t * 2.2)) * 0.35
            Circle()
                .fill((active ? Color.green : Color.orange).opacity(0.22))
                .frame(width: 26 * scale, height: 26 * scale)
                .overlay {
                    Circle()
                        .fill(active ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                }
        }
        .frame(width: 30, height: 30)
    }
}
