import SwiftUI

struct PushCard<Footer: View>: View {
    let title: String
    let message: String?
    let when: String?
    var avatar: String? = nil
    var avatarURL: String? = nil
    var tint: Color? = nil
    var expanded = false
    @ViewBuilder let footer: Footer

    @State private var footerHeight: CGFloat = 0

    private let shape = RoundedRectangle(cornerRadius: Theme.Radius.notification, style: .continuous)

    init(
        title: String,
        body: String?,
        when: String?,
        avatar: String? = nil,
        avatarURL: String? = nil,
        tint: Color? = nil,
        expanded: Bool = false,
        @ViewBuilder footer: () -> Footer
    ) {
        self.title = title
        self.message = body
        self.when = when
        self.avatar = avatar
        self.avatarURL = avatarURL
        self.tint = tint
        self.expanded = expanded
        self.footer = footer()
    }

    private var fallbackIcon: UIImage? {
        AvatarStore.image(for: avatarURL) ?? avatar.flatMap(AgentLabel.image(for:))
    }

    @ViewBuilder private var iconFallback: some View {
        if let fallbackIcon {
            Image(uiImage: fallbackIcon).resizable()
        } else {
            Image("Mark").resizable()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                Group {
                    if let avatarURL, let remote = URL(string: avatarURL) {
                        AsyncImage(url: remote) { image in
                            image.resizable()
                        } placeholder: {
                            iconFallback
                        }
                        .task { await AvatarStore.warm(avatarURL) }
                    } else {
                        iconFallback
                    }
                }
                    .frame(width: 38, height: 38)
                    .clipShape(.rect(cornerRadius: 11, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).strokeBorder(Theme.ring, lineWidth: 1))
                    .overlay(alignment: .bottomTrailing) {
                        if let tint {
                            Circle()
                                .fill(tint)
                                .frame(width: 12, height: 12)
                                .overlay(Circle().strokeBorder(Theme.bg1, lineWidth: 2))
                                .offset(x: 3, y: 3)
                        }
                    }

                VStack(alignment: .leading, spacing: 0) {
                    Text(title)
                        .typo(15, weight: .semibold)
                        .foregroundStyle(Theme.fg4)
                        .lineLimit(expanded ? nil : 1)
                        .truncationMode(.tail)
                        .padding(.trailing, when == nil ? 0 : 56)
                    if let message {
                        Text(message)
                            .typo(15)
                            .foregroundStyle(Theme.fg3)
                            .lineLimit(expanded ? nil : 4)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(alignment: .topTrailing) {
                if let when {
                    Text(when)
                        .typo(FontSize.xs)
                        .foregroundStyle(Theme.fg2)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            footer
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
        }
        .background {
            ZStack(alignment: .bottom) {
                Theme.bg1
                Theme.bg2.frame(height: footerHeight)
            }
            .clipShape(shape)
        }
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.ring, lineWidth: 1))
        .compositingGroup()
        .shadow(color: Theme.shadow.opacity(0.6), radius: 1.5, y: 1)
        .shadow(color: Theme.shadow.opacity(0.5), radius: 7, y: 6)
    }
}

extension PushCard where Footer == EmptyView {
    init(title: String, body: String?, when: String?, avatar: String? = nil, avatarURL: String? = nil, tint: Color? = nil, expanded: Bool = false) {
        self.init(title: title, body: body, when: when, avatar: avatar, avatarURL: avatarURL, tint: tint, expanded: expanded) { EmptyView() }
    }
}

struct CardFooter<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Theme.ring).frame(height: 1)
            HStack(spacing: 6) {
                content
            }
            .typo(FontSize.xs, weight: .medium)
            .foregroundStyle(Theme.fg2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 12) {
        PushCard(title: "Tests passed", body: "142 passed in 38s.", when: "now", avatar: "claude-code")
        PushCard(title: "Custom agent", body: "Gets a monogram.", when: "now", avatar: "my-bot")
        PushCard(title: "Reminder", body: nil, when: "now")
        PushCard(title: "A very long notification title that will definitely not fit on one line", body: "Short body.", when: "now")
        PushCard(
            title: "Waiting on you",
            body: "The migration touches the subscribers table and will lock it for roughly forty seconds during the backfill. Run it against production now, or wait for the maintenance window tonight?",
            when: "now",
            tint: Theme.amber
        )
        PushCard(title: "Migrations applied", body: "All 7 applied cleanly.", when: "52m ago", avatar: "claude-code", tint: Theme.green) {
            CardFooter {
                Icon("IconCircleCheckFilled", size: 14).foregroundStyle(Theme.green)
                Text("Finished after 4m 12s")
            }
        }
    }
    .padding(24)
    .background(Theme.brand1)
}
