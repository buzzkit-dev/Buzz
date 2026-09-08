import ActivityKit
import Foundation

@MainActor
@Observable
final class ActivityMonitor {
    var state: BuzzActivityAttributes.ContentState?

    private var started = false
    private var previewing = false

    func start() {
        guard !started else { return }
        started = true

        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewLive") {
                previewing = true
                state = BuzzSamples.many
                return
            }
        #endif

        for activity in Activity<BuzzActivityAttributes>.activities {
            follow(activity)
        }
        Task {
            for await activity in Activity<BuzzActivityAttributes>.activityUpdates {
                follow(activity)
            }
        }
    }

    func reconcile() async {
        guard !previewing, let client = PingClient.paired() else { return }
        guard let snapshot = try? await client.snapshot() else { return }
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BuzzMirrorSnapshot") {
                state = snapshot.activity.isQuiet ? nil : snapshot.activity
                return
            }
        #endif
        let local = Activity<BuzzActivityAttributes>.activities

        for activity in local {
            let boxed = Unchecked(activity)
            if snapshot.activity.isQuiet || (snapshot.activityId != nil && snapshot.activityId != activity.id) {
                await boxed.value.end(nil, dismissalPolicy: .immediate)
            } else if snapshot.activityId == activity.id, !activity.content.state.matches(snapshot.activity) {
                await boxed.value.update(.init(state: snapshot.activity, staleDate: nil))
            }
        }

        if local.isEmpty, snapshot.activityId == nil, !snapshot.activity.isQuiet {
            _ = try? Activity.request(
                attributes: BuzzActivityAttributes(),
                content: .init(state: snapshot.activity, staleDate: nil),
                pushType: .token
            )
        } else if local.isEmpty {
            state = nil
        }
    }

    private func follow(_ activity: Activity<BuzzActivityAttributes>) {
        let boxed = Unchecked(activity)
        state = activity.content.state

        Task {
            for await content in boxed.value.contentUpdates {
                state = content.state
            }
        }
        Task {
            for await phase in boxed.value.activityStateUpdates {
                guard phase == .ended || phase == .dismissed else { continue }
                if Activity<BuzzActivityAttributes>.activities.isEmpty { state = nil }
                return
            }
        }
    }
}

extension ActivityMonitor {
    static var livePreview: ActivityMonitor {
        let monitor = ActivityMonitor()
        monitor.state = BuzzSamples.many
        return monitor
    }

    static var idlePreview: ActivityMonitor {
        ActivityMonitor()
    }
}
