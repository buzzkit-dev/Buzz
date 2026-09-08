import SwiftUI

struct Spinner: View {
    var size: CGFloat = 20
    var color: Color = Theme.fg4
    var speed: Double = 0.9

    private var strokeWidth: CGFloat { size * 2.5 / 24 }

    var body: some View {
        TimelineView(.animation) { context in
            let elapsed = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: speed)
            ring.rotationEffect(.degrees(elapsed / speed * 360))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Loading")
    }

    private var ring: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.3), lineWidth: strokeWidth)
            Circle()
                .trim(from: 0, to: 0.25)
                .stroke(color, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
        }
        .padding(strokeWidth / 2)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack(spacing: 20) {
        Spinner(size: 20)
        Spinner(size: 24, color: Theme.fg2)
        Spinner(size: 32, color: Theme.green)
    }
    .padding(24)
    .background(Theme.background)
}
