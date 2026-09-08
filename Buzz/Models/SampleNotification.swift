import Foundation

enum SampleNotification: Identifiable {
    case banner(id: String, title: String, body: String, when: String)
    case activity(id: String, state: BuzzActivityAttributes.ContentState)

    var id: String {
        switch self {
        case let .banner(id, _, _, _), let .activity(id, _): id
        }
    }

    var isBanner: Bool {
        if case .banner = self { return true }
        return false
    }

    static let pool: [SampleNotification] = [
        .banner(id: "tests", title: "Tests passed", body: "142 passed in 38s.", when: "now"),
        .activity(id: "migrations", state: BuzzSamples.single),
        .banner(id: "waiting", title: "Waiting on you", body: "Claude Code is blocked at your desk.", when: "now"),
        .banner(id: "deploy", title: "Deploy finished", body: "api v2.14 is live.", when: "2m ago"),
        .activity(id: "agents", state: BuzzSamples.many),
        .banner(id: "build", title: "Build failed", body: "3 type errors in HomeView.swift.", when: "now"),
    ]
}
