import SwiftUI

public struct AgentAvatar: View {
    private let agent: String?
    private let avatarURL: String?
    private let size: CGFloat
    private let status: BuzzStatus?
    private let dotBorder: Color

    public init(
        agent: String?,
        avatarURL: String? = nil,
        size: CGFloat,
        status: BuzzStatus? = nil,
        dotBorder: Color = Theme.ink
    ) {
        self.agent = agent
        self.avatarURL = avatarURL
        self.size = size
        self.status = status
        self.dotBorder = dotBorder
    }

    private var image: UIImage? {
        AvatarStore.image(for: avatarURL) ?? agent.flatMap(AgentLabel.image(for:))
    }

    public var body: some View {
        Group {
            if let image {
                Image(uiImage: image).resizable()
            } else {
                Image("Mark").resizable()
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: size * 0.29, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: size * 0.29, style: .continuous).strokeBorder(.primary.opacity(0.08), lineWidth: 0.5))
        .overlay(alignment: .bottomTrailing) {
            if let status {
                Circle()
                    .fill(status.tint)
                    .frame(width: size * 0.34, height: size * 0.34)
                    .overlay(Circle().strokeBorder(dotBorder, lineWidth: max(1.5, size * 0.055)))
                    .offset(x: size * 0.1, y: size * 0.1)
            }
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        AgentAvatar(agent: "claude-code", size: 36, status: .working)
        AgentAvatar(agent: "codex", size: 36, status: .waiting)
        AgentAvatar(agent: "nightly-bot", size: 36, status: .done)
        AgentAvatar(agent: nil, size: 36)
        AgentAvatar(agent: "cursor", size: 20)
    }
    .padding(24)
    .background(Theme.ink)
}
