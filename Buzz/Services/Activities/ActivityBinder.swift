import ActivityKit
import BuzzKit
import OSLog

private let activityLog = Logger(subsystem: "studio.overclock.buzz", category: "Activities")

enum ActivityBinder {
    static func registerToken(_ id: String, _ token: Data) async {
        do {
            try await BuzzKit.activities.register(
                id: id,
                token: token,
                attributesType: String(describing: BuzzActivityAttributes.self)
            )
            activityLog.info("Registered activity token for \(id, privacy: .public)")
        } catch {
            activityLog.error("Activity token registration failed: \(error, privacy: .public)")
        }
    }

    static func start() {
        let existing = Activity<BuzzActivityAttributes>.activities
        let startToken = Activity<BuzzActivityAttributes>.pushToStartToken
        activityLog.info(
            "start: \(existing.count, privacy: .public) existing, enabled=\(ActivityAuthorizationInfo().areActivitiesEnabled, privacy: .public), pushToStartToken=\(startToken?.map { String(format: "%02x", $0) }.joined().prefix(16) ?? "nil", privacy: .public)"
        )
        Task {
            for await token in Activity<BuzzActivityAttributes>.pushToStartTokenUpdates {
                activityLog.info(
                    "pushToStartTokenUpdates yielded \(token.map { String(format: "%02x", $0) }.joined().prefix(16), privacy: .public)"
                )
                do {
                    try await BuzzKit.activities.registerPushToStartToken(
                        token,
                        attributesType: String(describing: BuzzActivityAttributes.self)
                    )
                    activityLog.info("push-to-start token registered")
                } catch {
                    activityLog.error("push-to-start registration failed: \(error, privacy: .public)")
                }
            }
        }
        for activity in existing {
            adopt(activity)
        }
        Task {
            for await activity in Activity<BuzzActivityAttributes>.activityUpdates {
                activityLog.info("activityUpdates yielded \(activity.id, privacy: .public)")
                adopt(activity)
            }
        }

        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BuzzStartLocalActivity"), existing.isEmpty {
                _ = try? Activity.request(
                    attributes: BuzzActivityAttributes(),
                    content: .init(state: BuzzSamples.single, staleDate: nil),
                    pushType: .token
                )
            }
        #endif
    }

    private static func adopt(_ activity: Activity<BuzzActivityAttributes>) {
        let boxed = Unchecked(activity)
        let id = activity.id

        Task {
            try? await PingClient.paired()?.bindActivity(id: id)
        }
        activityLog.info(
            "adopt \(id, privacy: .public) state=\(String(describing: activity.activityState), privacy: .public) hasToken=\(activity.pushToken != nil, privacy: .public)"
        )
        Task {
            if let current = boxed.value.pushToken { await registerToken(id, current) }
            for await token in boxed.value.pushTokenUpdates {
                activityLog.info("pushTokenUpdates yielded for \(id, privacy: .public)")
                await registerToken(id, token)
            }
            activityLog.info("pushTokenUpdates ended for \(id, privacy: .public)")
        }
        Task {
            for await state in boxed.value.activityStateUpdates {
                guard state == .dismissed || state == .ended else { continue }
                try? await PingClient.paired()?.unbindActivity()
                return
            }
        }
    }
}
