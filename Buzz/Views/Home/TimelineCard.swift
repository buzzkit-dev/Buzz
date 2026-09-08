import SwiftUI

struct TimelineCard: View {
    let event: TimelineEvent

    var body: some View {
        card(expanded: false)
            .contextMenu {
                Button("Copy") { UIPasteboard.general.string = [event.title, event.body].compactMap { $0 }.joined(separator: "\n") }
            }
    }

    private func card(expanded: Bool) -> some View {
        PushCard(title: event.title, body: event.body, when: when, avatar: event.agent, avatarURL: event.avatar, tint: tint, expanded: expanded) {
            if event.kind == .session, let outcome = sessionOutcome {
                outcome
            }
        }
        .transaction { $0.animation = nil }
    }

    private var sessionOutcome: CardFooter<AnyView>? {
        guard let status = event.buzzStatus, status == .done, let milliseconds = event.durationMs else { return nil }
        return CardFooter {
            AnyView(
                HStack(spacing: 6) {
                    Icon(status.icon, size: 14).foregroundStyle(status.tint)
                    Text("Finished after \(TimelineClock.duration(milliseconds: milliseconds))")
                }
            )
        }
    }

    private var tint: Color? {
        switch event.kind {
        case .connected: Theme.green
        case .session: event.buzzStatus?.tint
        case .notification: nil
        }
    }

    private var when: String {
        TimelineClock.label(for: event.at)
    }
}

enum TimelineClock {
    static func duration(milliseconds: Int) -> String {
        let seconds = max(0, milliseconds / 1000)
        if seconds < 60 { return "\(seconds)s" }
        if seconds < 3600 { return "\(seconds / 60)m \(seconds % 60)s" }
        return "\(seconds / 3600)h \(seconds % 3600 / 60)m"
    }

    static func label(for date: Date, now: Date = .now) -> String {
        let seconds = max(0, now.timeIntervalSince(date))
        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86_400 { return "\(Int(seconds / 3600))h ago" }
        if seconds < 7 * 86_400 { return date.formatted(.dateTime.weekday(.abbreviated)) }
        return date.formatted(.dateTime.month(.abbreviated).day())
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 12) {
            ForEach(TimelineEvent.samples) { event in
                TimelineCard(event: event)
            }
        }
        .padding(16)
    }
    .background(Theme.brand1)
    .environment(TimelineModel.samplePreview)
}
