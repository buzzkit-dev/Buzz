import Foundation

public struct TimelineEvent: Codable, Identifiable, Hashable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case connected
        case notification
        case session

        public init(from decoder: any Decoder) throws {
            let raw = try decoder.singleValueContainer().decode(String.self)
            self = Kind(rawValue: raw) ?? .notification
        }
    }

    public var id: Int
    public var kind: Kind
    public var title: String
    public var body: String?
    public var status: String?
    public var agent: String?
    public var project: String?
    public var avatar: String?
    public var session: String?
    public var url: URL?
    public var durationMs: Int?
    public var at: Date

    public init(
        id: Int,
        kind: Kind,
        title: String,
        body: String? = nil,
        status: String? = nil,
        agent: String? = nil,
        project: String? = nil,
        avatar: String? = nil,
        session: String? = nil,
        url: URL? = nil,
        durationMs: Int? = nil,
        at: Date
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.status = status
        self.agent = agent
        self.project = project
        self.avatar = avatar
        self.session = session
        self.url = url
        self.durationMs = durationMs
        self.at = at
    }

    public var buzzStatus: BuzzStatus? {
        status.map(BuzzStatus.init)
    }
}

struct TimelineResponse: Decodable {
    var events: [TimelineEvent]
}
