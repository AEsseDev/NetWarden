import SwiftUI

struct CyberBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            Canvas { canvas, size in
                let rect = CGRect(origin: .zero, size: size)
                canvas.fill(Path(rect), with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.02, green: 0.04, blue: 0.10),
                        Color(red: 0.01, green: 0.01, blue: 0.03)
                    ]),
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                ))

                for i in 0..<28 {
                    let phase = Double(i) * 0.33
                    let x = (sin(t * 0.20 + phase) * 0.45 + 0.5) * size.width
                    let y = (cos(t * 0.26 + phase * 1.4) * 0.45 + 0.5) * size.height
                    let r = 1.8 + abs(sin(t * 0.9 + phase)) * 2.8
                    let c = Color.cyan.opacity(0.15 + abs(sin(t + phase)) * 0.25)
                    canvas.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(c))
                }

                var grid = Path()
                let spacing: CGFloat = 28
                let shift = CGFloat((t * 24).truncatingRemainder(dividingBy: Double(spacing)))
                stride(from: -spacing + shift, through: size.width + spacing, by: spacing).forEach { x in
                    grid.move(to: CGPoint(x: x, y: 0))
                    grid.addLine(to: CGPoint(x: x, y: size.height))
                }
                stride(from: -spacing + shift, through: size.height + spacing, by: spacing).forEach { y in
                    grid.move(to: CGPoint(x: 0, y: y))
                    grid.addLine(to: CGPoint(x: size.width, y: y))
                }
                canvas.stroke(grid, with: .color(Color.cyan.opacity(0.06)), lineWidth: 0.8)
            }
        }
        .ignoresSafeArea()
    }
}

struct NeonCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
            content
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.07))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.28), lineWidth: 1)
                )
        )
        .shadow(color: .cyan.opacity(0.18), radius: 12, x: 0, y: 0)
    }
}
