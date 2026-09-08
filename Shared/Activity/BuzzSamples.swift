import Foundation

public enum BuzzSamples {
    public static let single = BuzzActivityAttributes.ContentState(
        headline: "Running migrations",
        detail: "3 of 7 applied",
        status: "working",
        live: 1,
        progress: 0.43,
        sessions: [
            BuzzSession(
                id: "buzzkit/ts-sdk",
                title: "Running migrations",
                body: "3 of 7 applied",
                agent: "claude-code",
                project: "buzzkit",
                avatar: nil,
                status: "working",
                progress: 0.43,
                step: nil,
                startedAt: "",
                updatedAt: ""
            )
        ]
    )

    public static let many = BuzzActivityAttributes.ContentState(
        headline: "3 agents working",
        detail: "buzzkit — Running migrations",
        status: "working",
        live: 3,
        overflow: 2,
        progress: 0.52,
        sessions: [
            session(id: "buzzkit/ts-sdk", title: "Running migrations", project: "buzzkit", progress: 0.52),
            session(id: "buzz/ios", title: "Building widget", project: "buzz", agent: "codex"),
            session(id: "marketing/page", title: "Writing copy", project: "marketing", agent: "cursor", status: "failed"),
        ]
    )

    public static let waiting = BuzzActivityAttributes.ContentState(
        headline: "Waiting on you",
        detail: "buzzkit — Deploy migration",
        status: "waiting",
        live: 2,
        waiting: 1,
        sessions: [
            BuzzSession(
                id: "buzzkit/ts-sdk",
                title: "Run the migration against production?",
                body: nil,
                agent: "claude-code",
                project: "buzzkit",
                avatar: nil,
                status: "waiting",
                progress: nil,
                step: nil,
                startedAt: "",
                updatedAt: ""
            ),
            session(id: "buzz/ios", title: "Building widget", project: "buzz", agent: "codex"),
        ]
    )

    private static func session(
        id: String,
        title: String,
        project: String,
        agent: String = "claude-code",
        status: String = "working",
        progress: Double? = nil
    ) -> BuzzSession {
        BuzzSession(
            id: id,
            title: title,
            body: nil,
            agent: agent,
            project: project,
            avatar: nil,
            status: status,
            progress: progress,
            step: nil,
            startedAt: "",
            updatedAt: ""
        )
    }
}
