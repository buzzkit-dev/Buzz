import ActivityKit
import Foundation

public struct BuzzActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable, Sendable {
        public var version: Int
        public var headline: String
        public var detail: String?
        public var status: String
        public var live: Int
        public var waiting: Int
        public var overflow: Int
        public var progress: Double?
        public var sessions: [BuzzSession]
        public var updatedAt: String

        public init(
            version: Int = BuzzActivityAttributes.schemaVersion,
            headline: String,
            detail: String? = nil,
            status: String = "working",
            live: Int = 0,
            waiting: Int = 0,
            overflow: Int = 0,
            progress: Double? = nil,
            sessions: [BuzzSession] = [],
            updatedAt: String = ""
        ) {
            self.version = version
            self.headline = headline
            self.detail = detail
            self.status = status
            self.live = live
            self.waiting = waiting
            self.overflow = overflow
            self.progress = progress
            self.sessions = sessions
            self.updatedAt = updatedAt
        }
    }

    public static let schemaVersion = 1

    public init() {}
}

public struct BuzzSession: Codable, Hashable, Identifiable, Sendable {
    public struct Step: Codable, Hashable, Sendable {
        public var current: Int
        public var total: Int
    }

    public var id: String
    public var title: String
    public var body: String?
    public var agent: String?
    public var project: String?
    public var avatar: String?
    public var status: String
    public var progress: Double?
    public var step: Step?
    public var startedAt: String
    public var updatedAt: String
}

public enum BuzzStatus: String {
    case working
    case waiting
    case done
    case failed

    public init(_ raw: String) {
        self = BuzzStatus(rawValue: raw) ?? .working
    }
}

extension BuzzSession {
    public var state: BuzzStatus { BuzzStatus(status) }

    public var fraction: Double? {
        if let progress { return progress }
        guard let step, step.total > 0 else { return nil }
        return min(1, Double(step.current) / Double(step.total))
    }
}

extension BuzzActivityAttributes.ContentState {
    public var state: BuzzStatus { BuzzStatus(status) }

    public var isQuiet: Bool { sessions.isEmpty }

    public func matches(_ other: Self) -> Bool {
        var mine = self
        var theirs = other
        mine.updatedAt = ""
        theirs.updatedAt = ""
        return mine == theirs
    }
}
