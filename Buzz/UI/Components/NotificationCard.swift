import SwiftUI

struct NotificationCard: View {
    let notification: SampleNotification

    private let shape = RoundedRectangle(cornerRadius: Theme.Radius.notification, style: .continuous)

    var body: some View {
        Group {
            switch notification {
            case let .banner(_, title, body, when):
                PushCard(title: title, body: body, when: when)
            case let .activity(_, state):
                LockScreenView(state: state)
                    .background(Theme.ink, in: shape)
                    .overlay(shape.strokeBorder(Theme.inkForeground.opacity(0.08), lineWidth: 1))
                    .overlay(shape.strokeBorder(Theme.ring, lineWidth: 1))
                    .shadow(color: Theme.shadow.opacity(0.6), radius: 1.5, y: 1)
                    .shadow(color: Theme.shadow.opacity(0.5), radius: 7, y: 6)
            }
        }
        .frame(width: 288)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        ForEach(SampleNotification.pool.prefix(3)) { notification in
            NotificationCard(notification: notification)
        }
    }
    .padding(24)
    .background(Theme.brand1)
}
