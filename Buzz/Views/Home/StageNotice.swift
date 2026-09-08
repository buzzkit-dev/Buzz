import SwiftUI

struct StageNotice: View {
    let icon: String
    let title: String
    let message: String
    var action: String?
    var loading = false
    var onAction: () -> Void = {}

    var body: some View {
        ZStack {
            NotificationStack(slots: Array(SampleNotification.pool.prefix(2)), arrived: true)
                .saturation(0)
                .opacity(0.07)
                .blur(radius: 2)
                .allowsHitTesting(false)

            VStack(spacing: 20) {
                Icon(icon, size: 28)
                    .foregroundStyle(Theme.fg3)
                    .frame(width: 60, height: 60)
                    .background(Theme.bg1, in: .circle)
                    .overlay(Circle().strokeBorder(Theme.ring, lineWidth: 1))
                    .shadow(color: Theme.shadow, radius: 10, y: 4)

                VStack(spacing: 2) {
                    Text(title)
                        .typo(FontSize.xl, weight: .medium)
                        .foregroundStyle(Theme.fg4)
                    Text(message)
                        .typo(FontSize.base)
                        .foregroundStyle(Theme.fg3)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let action {
                    AppButton(title: action, loading: loading, fullWidth: false, action: onAction)
                }
            }
            .padding(.horizontal, 32)
        }
    }
}

extension StageNotice {
    static func notificationsOff() -> StageNotice {
        StageNotice(
            icon: "IconBellOffFilled",
            title: "Notifications are off",
            message: "Nothing can reach you until you turn them on.",
            action: "Open Settings"
        ) {
            guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
            UIApplication.shared.open(url)
        }
    }

    static func connection(_ issue: ConnectionIssue, loading: Bool, retry: @escaping () -> Void) -> StageNotice {
        StageNotice(
            icon: "IconExclamationTriangleFilled",
            title: issue.title,
            message: issue.message,
            action: issue.action,
            loading: loading,
            onAction: retry
        )
    }
}

#Preview("Notifications off") {
    Stage(muted: true) { StageNotice.notificationsOff() }
        .frame(height: 420)
        .padding(24)
        .background(Theme.background)
}

#Preview("Offline") {
    Stage(muted: true) { StageNotice.connection(ConnectionIssue(kind: .offline), loading: false) {} }
        .frame(height: 420)
        .padding(24)
        .background(Theme.background)
}
