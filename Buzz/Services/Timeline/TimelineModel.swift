import Foundation

private let connectedKey = "buzz.timeline.hasConnected"
private let cacheKey = "buzz.timeline.cache"

@MainActor
@Observable
final class TimelineModel {
    private(set) var events: [TimelineEvent] = TimelineModel.readCache() {
        didSet {
            if !events.isEmpty { hasConnected = true }
            if !isPreview { Self.writeCache(events) }
        }
    }
    private(set) var isLoading = false
    private(set) var isPreview = false
    private(set) var hasConnected = UserDefaults.standard.bool(forKey: connectedKey) {
        didSet { if !isPreview { UserDefaults.standard.set(hasConnected, forKey: connectedKey) } }
    }

    var hasEvents: Bool { !events.isEmpty }

    func refresh() async {
        guard !isPreview, !isLoading, let client = PingClient.paired() else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            events = try await client.timeline()
        } catch {
            return
        }
    }

    func listen() async {
        guard !isPreview else { return }
        var attempt = 0
        while !Task.isCancelled {
            guard let url = PingClient.paired()?.streamURL else {
                try? await Task.sleep(for: .seconds(2))
                continue
            }
            let socket = URLSession.shared.webSocketTask(with: url)
            socket.resume()
            let connected = await receive(from: socket)
            socket.cancel(with: .goingAway, reason: nil)
            guard !Task.isCancelled else { return }
            attempt = connected ? 0 : min(attempt + 1, 5)
            try? await Task.sleep(for: .seconds(connected ? 1 : Double(1 << attempt)))
        }
    }

    private func receive(from socket: URLSessionWebSocketTask) async -> Bool {
        var received = false
        while !Task.isCancelled {
            do {
                _ = try await socket.receive()
                received = true
                await refresh()
            } catch {
                return received
            }
        }
        return received
    }

    func forget() {
        events = []
        hasConnected = false
    }

    func clear() async {
        if isPreview {
            events = []
            return
        }
        guard let client = PingClient.paired() else { return }

        do {
            try await client.clearTimeline()
            events = []
        } catch {
            return
        }
    }

    private static func readCache() -> [TimelineEvent] {
        guard let data = UserDefaults.standard.data(forKey: cacheKey) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([TimelineEvent].self, from: data)) ?? []
    }

    private static func writeCache(_ events: [TimelineEvent]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(events) else { return }
        UserDefaults.standard.set(data, forKey: cacheKey)
    }

    func showPreviewSamples(_ shown: Bool) {
        guard isPreview else { return }
        events = shown ? TimelineEvent.samples : []
    }
}

#if DEBUG
    extension TimelineModel {
        static func launch() -> TimelineModel {
            ProcessInfo.processInfo.arguments.contains("-BuzzPreviewTimeline") ? samplePreview : TimelineModel()
        }
    }
#endif

extension TimelineModel {
    static var samplePreview: TimelineModel {
        let model = TimelineModel()
        model.isPreview = true
        model.events = TimelineEvent.samples
        return model
    }

    static var emptyPreview: TimelineModel {
        let model = TimelineModel()
        model.isPreview = true
        model.events = []
        model.hasConnected = false
        return model
    }
}

extension TimelineEvent {
    static let samples: [TimelineEvent] = [
        TimelineEvent(
            id: 6,
            kind: .session,
            title: "Waiting on you",
            body: "The migration touches the subscribers table and will lock it for roughly forty seconds during the backfill. Come approve it at your desk before I run it against production.",
            status: "waiting",
            agent: "claude-code",
            project: "buzzkit",
            session: "buzzkit/ts-sdk",
            at: .now.addingTimeInterval(-40)
        ),
        TimelineEvent(
            id: 5,
            kind: .session,
            title: "Running migrations",
            body: "3 of 7 applied",
            status: "working",
            agent: "claude-code",
            project: "buzzkit",
            session: "buzzkit/ts-sdk",
            at: .now.addingTimeInterval(-3 * 60)
        ),
        TimelineEvent(
            id: 4,
            kind: .notification,
            title: "Tests passed",
            body: "142 passed in 38s.",
            at: .now.addingTimeInterval(-14 * 60)
        ),
        TimelineEvent(id: 12, kind: .notification, title: "Reminder", at: .now.addingTimeInterval(-15 * 60)),
        TimelineEvent(
            id: 11,
            kind: .notification,
            title: "Build failed",
            body: "Line one of the body.\nLine two after a newline.\nLine three, still going.",
            at: .now.addingTimeInterval(-16 * 60)
        ),
        TimelineEvent(
            id: 10,
            kind: .notification,
            title: "Deploy finished",
            body: "api v2.14 is live on api.buzzkit.dev. Migrations 12 through 15 applied, the workflow engine restarted cleanly, and the device suite is green on the Mac mini. Nothing else needs your attention tonight.",
            at: .now.addingTimeInterval(-17 * 60)
        ),
        TimelineEvent(
            id: 9,
            kind: .notification,
            title: "A very long notification title that will definitely not fit on a single line",
            body: "Short body.",
            at: .now.addingTimeInterval(-18 * 60)
        ),
        TimelineEvent(
            id: 2,
            kind: .session,
            title: "Deploy finished",
            body: "api v2.14 is live.",
            status: "done",
            agent: "codex",
            project: "buzzkit",
            session: "buzzkit/deploy",
            durationMs: 252_000,
            at: .now.addingTimeInterval(-3 * 3600)
        ),
        TimelineEvent(
            id: 1,
            kind: .connected,
            title: "Agent connected",
            body: "A coding agent claimed your endpoint.",
            at: .now.addingTimeInterval(-26 * 3600)
        ),
    ]
}
