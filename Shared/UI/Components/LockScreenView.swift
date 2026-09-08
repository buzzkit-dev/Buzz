import SwiftUI

public struct LockScreenView: View {
    private let state: BuzzActivityAttributes.ContentState

    public init(state: BuzzActivityAttributes.ContentState) {
        self.state = state
    }

    public var body: some View {
        VStack(spacing: 0) {
            if state.sessions.count > 1 {
                SessionRows(state: state)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ActivityHeader(state: state)
                    if let fraction = state.progress {
                        ProgressBar(fraction: fraction, tint: state.state.tint)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }
}

public struct SessionRows: View {
    private let state: BuzzActivityAttributes.ContentState
    private let limit: Int
    private let dotBorder: Color
    private let island: Bool

    public init(state: BuzzActivityAttributes.ContentState, limit: Int = 3, dotBorder: Color = Theme.ink, island: Bool = false) {
        self.state = state
        self.limit = limit
        self.dotBorder = dotBorder
        self.island = island
    }

    private var shown: Int {
        state.sessions.count + state.overflow > limit ? limit - 1 : limit
    }

    private var hidden: Int {
        state.overflow + max(0, state.sessions.count - shown)
    }

    private var pair: Bool {
        state.sessions.count + state.overflow <= 2
    }

    private var roomy: Bool {
        !island && pair
    }

    private var dense: Bool {
        island && !pair
    }

    private var rowPadding: CGFloat {
        if roomy { return 12 }
        return dense ? 5 : 8
    }

    private var avatarSize: CGFloat {
        if roomy { return 36 }
        return dense ? 28 : 32
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(state.sessions.prefix(shown).enumerated()), id: \.element.id) { index, session in
                if index > 0 {
                    Rectangle().fill(Theme.inkForeground.opacity(0.1)).frame(height: 1).padding(.leading, avatarSize + 28)
                }
                HStack(alignment: .center, spacing: 12) {
                    AgentAvatar(agent: session.agent, avatarURL: session.avatar, size: avatarSize, status: session.state, dotBorder: dotBorder)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(session.title)
                            .typo(15, weight: .semibold)
                            .foregroundStyle(Theme.inkForeground)
                            .lineLimit(1)
                        if let detail = session.body ?? session.project {
                            Text(detail)
                                .typo(FontSize.xs)
                                .foregroundStyle(Theme.inkForeground.opacity(0.55))
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 8)
                    SessionTrailing(session: session)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, rowPadding)
            }

            if hidden > 0 {
                Rectangle().fill(Theme.inkForeground.opacity(0.1)).frame(height: 1).padding(.leading, 56)
                Text("and \(hidden) more")
                    .typo(FontSize.xs)
                    .foregroundStyle(Theme.inkForeground.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 56)
                    .padding(.top, dense ? 5 : 7)
                    .padding(.bottom, dense ? 5 : 10)
            }
        }
        .padding(.top, island ? 2 : (roomy ? 4 : 6))
        .padding(.bottom, hidden > 0 || island ? 0 : (roomy ? 4 : 6))
    }
}

public struct SessionTrailing: View {
    private let session: BuzzSession

    public init(session: BuzzSession) {
        self.session = session
    }

    public var body: some View {
        switch session.state {
        case .working:
            if let fraction = session.fraction {
                Text("\(Int(fraction * 100))%")
                    .typo(FontSize.sm, weight: .medium)
                    .monospacedDigit()
                    .foregroundStyle(Theme.inkForeground.opacity(0.6))
                    .contentTransition(.numericText(value: fraction))
            }
        case .waiting:
            StatusIcon(.waiting, size: 16)
        case .done:
            StatusIcon(.done, size: 16)
        case .failed:
            StatusIcon(.failed, size: 16)
        }
    }
}

public struct ActivityHeader: View {
    private let state: BuzzActivityAttributes.ContentState
    private let dotBorder: Color
    private let detailLines: Int

    public init(state: BuzzActivityAttributes.ContentState, dotBorder: Color = Theme.ink, detailLines: Int = 2) {
        self.state = state
        self.dotBorder = dotBorder
        self.detailLines = detailLines
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            AgentAvatar(agent: state.leadAgent, avatarURL: state.leadAvatar, size: 36, status: state.state, dotBorder: dotBorder)

            VStack(alignment: .leading, spacing: 1) {
                Text(state.headline)
                    .typo(15, weight: .semibold)
                    .foregroundStyle(Theme.inkForeground)
                    .lineLimit(1)
                if let detail = state.detail {
                    Text(detail)
                        .typo(FontSize.xs)
                        .foregroundStyle(Theme.inkForeground.opacity(0.55))
                        .lineLimit(detailLines)
                }
            }

            Spacer(minLength: 8)
            TrailingBadge(state: state)
        }
    }
}

public struct TrailingBadge: View {
    private let state: BuzzActivityAttributes.ContentState

    public init(state: BuzzActivityAttributes.ContentState) {
        self.state = state
    }

    public var body: some View {
        if state.waiting > 0 {
            Badge(text: state.waiting == 1 ? "Waiting" : "\(state.waiting) waiting", tint: Theme.amber)
        } else if state.state == .failed {
            Badge(text: "Failed", tint: Theme.red)
        } else if state.state == .done {
            Badge(text: "Done", tint: Theme.green)
        } else if let fraction = state.progress {
            Text("\(Int(fraction * 100))%")
                .typo(FontSize.sm, weight: .medium)
                .monospacedDigit()
                .foregroundStyle(Theme.inkForeground.opacity(0.6))
                .contentTransition(.numericText(value: fraction))
        } else if state.live > 1 {
            Badge(text: "\(state.live) live", tint: Theme.sky)
        }
    }

    private struct Badge: View {
        let text: String
        let tint: Color

        var body: some View {
            Text(text)
                .typo(FontSize.xs, weight: .medium)
                .foregroundStyle(tint)
                .padding(.horizontal, 8)
                .frame(height: 22)
                .background(tint.opacity(0.16), in: .capsule)
        }
    }
}

extension BuzzActivityAttributes.ContentState {
    public var leadSession: BuzzSession? { sessions.first }

    public var leadAgent: String? { leadSession?.agent }

    public var leadAvatar: String? { leadSession?.avatar }
}

#Preview("One agent") {
    LockScreenView(state: BuzzSamples.single)
        .background(Theme.ink, in: .rect(cornerRadius: Theme.Radius.notification, style: .continuous))
        .padding()
}

#Preview("Several agents") {
    LockScreenView(state: BuzzSamples.many)
        .background(Theme.ink, in: .rect(cornerRadius: Theme.Radius.notification, style: .continuous))
        .padding()
}

#Preview("Waiting on you") {
    LockScreenView(state: BuzzSamples.waiting)
        .background(Theme.ink, in: .rect(cornerRadius: Theme.Radius.notification, style: .continuous))
        .padding()
}
