import ActivityKit
import SwiftUI
import WidgetKit

struct BuzzLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: BuzzActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .activityBackgroundTint(Theme.ink.opacity(0.94))
                .activitySystemActionForegroundColor(Theme.inkForeground)
        } dynamicIsland: { context in
            let state = context.state

            return DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    if state.sessions.count <= 1 {
                        ActivityHeader(state: state, dotBorder: .black, detailLines: 1)
                            .padding(.horizontal, 4)
                            .padding(.top, 2)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if state.sessions.count > 1 {
                        SessionRows(state: state, limit: 3, dotBorder: .black, island: true)
                            .padding(.horizontal, -4)
                    } else if let fraction = state.progress {
                        ProgressBar(fraction: fraction, tint: state.state.tint)
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                            .padding(.bottom, 6)
                    }
                }
            } compactLeading: {
                AgentAvatar(agent: state.leadAgent, avatarURL: state.leadAvatar, size: 20)
                    .padding(.leading, 2)
                    .padding(.trailing, 4)
            } compactTrailing: {
                CompactTrailing(state: state)
                    .padding(.leading, 4)
                    .padding(.trailing, 2)
            } minimal: {
                AgentAvatar(agent: state.leadAgent, avatarURL: state.leadAvatar, size: 20, status: state.state, dotBorder: .black)
            }
            .keylineTint(state.state.tint)
        }
    }
}

private struct CompactTrailing: View {
    let state: BuzzActivityAttributes.ContentState

    var body: some View {
        if state.waiting > 0 {
            StatusIcon(.waiting, size: 16)
        } else if state.state == .failed {
            StatusIcon(.failed, size: 16)
        } else if state.state == .done {
            StatusIcon(.done, size: 16)
        } else if let fraction = state.progress {
            Text("\(Int(fraction * 100))%")
                .typo(13, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(Theme.inkForeground)
                .contentTransition(.numericText(value: fraction))
        } else if state.live > 1 {
            Text("\(state.live)")
                .typo(13, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(Theme.inkForeground)
        } else {
            StatusIcon(.working, size: 16)
        }
    }
}
