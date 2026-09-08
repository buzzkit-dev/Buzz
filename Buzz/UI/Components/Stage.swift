import SwiftUI

struct Stage<Content: View>: View {
    var muted = false
    @ViewBuilder let content: Content

    private let shape = RoundedRectangle(cornerRadius: Theme.Radius.sheet, style: .continuous)

    var body: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [muted ? Theme.bg2 : Theme.brand1, Theme.bg2, Theme.bg3],
                startPoint: .top,
                endPoint: .bottom
            )
            RadialGradient(
                colors: [Theme.brand2.opacity(muted ? 0 : 0.7), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 260
            )
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.ring, lineWidth: 1))
        .animation(Motion.swap, value: muted)
    }
}

#Preview {
    Stage {
        NotificationStack(slots: Array(SampleNotification.pool.prefix(2)), arrived: true)
    }
    .frame(height: 320)
    .padding(24)
}
