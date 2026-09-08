import Foundation

public struct PingClient: Sendable {
    public static var host: URL { PingEnvironment.host }

    private let endpoint: URL

    public init(endpoint: URL) {
        self.endpoint = endpoint
    }

    public static func paired() -> PingClient? {
        guard let endpoint = BuzzStore.endpoint else { return nil }
        return PingClient(endpoint: endpoint)
    }

    public static func pair() async throws -> Pairing {
        var request = URLRequest(url: host.appending(path: "pair"))
        request.httpMethod = "POST"

        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try assertOK(response, data)

        return try JSONDecoder().decode(Pairing.self, from: data)
    }

    public func snapshot() async throws -> Snapshot {
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)

        return try JSONDecoder().decode(Snapshot.self, from: data)
    }

    public func timeline() async throws -> [TimelineEvent] {
        var request = URLRequest(url: endpoint.appending(path: "timeline"))
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TimelineResponse.self, from: data).events
    }

    public var streamURL: URL? {
        var components = URLComponents(url: endpoint.appending(path: "stream"), resolvingAgainstBaseURL: false)
        components?.scheme = endpoint.scheme == "https" ? "wss" : "ws"
        return components?.url
    }

    public func clearTimeline() async throws {
        var request = URLRequest(url: endpoint.appending(path: "timeline"))
        request.httpMethod = "DELETE"
        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)
    }

    public func bindActivity(id: String) async throws {
        var request = URLRequest(url: endpoint.appending(path: "activity"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.httpBody = try JSONEncoder().encode(["activityId": id])

        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)
    }

    public func unbindActivity() async throws {
        var request = URLRequest(url: endpoint.appending(path: "activity"))
        request.httpMethod = "DELETE"

        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)
    }

    public func rotate() async throws -> Rotation {
        var request = URLRequest(url: endpoint.appending(path: "rotate"))
        request.httpMethod = "POST"

        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)

        return try JSONDecoder().decode(Rotation.self, from: data)
    }

    public func pairingCode() async throws -> PairingCode {
        var request = URLRequest(url: endpoint.appending(path: "code"))
        request.httpMethod = "POST"

        request.timeoutInterval = 15
        let (data, response) = try await URLSession.shared.data(for: request)
        try Self.assertOK(response, data)

        return try JSONDecoder().decode(PairingCode.self, from: data)
    }

    private static func assertOK(_ response: URLResponse, _ data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw PingError.unreachable }
        guard (200..<300).contains(http.statusCode) else {
            let failure = try? JSONDecoder().decode(Failure.self, from: data)
            throw PingError.rejected(status: http.statusCode, message: failure?.error.message ?? "Buzz could not reach the server")
        }
    }
}

public struct Pairing: Decodable, Sendable {
    public struct Identity: Decodable, Sendable {
        public var apiUrl: URL
        public var publishableKey: String
        public var externalId: String
        public var identityHash: String?
    }

    public var key: String
    public var endpoint: URL
    public var buzzkit: Identity
}

public struct Snapshot: Decodable, Sendable {
    public var activityId: String?
    public var activity: BuzzActivityAttributes.ContentState
}

public struct Rotation: Decodable, Sendable {
    public var key: String
    public var endpoint: URL
}

public struct PairingCode: Decodable, Sendable {
    public var code: String
    public var expiresIn: Int
}

struct Failure: Decodable {
    struct Detail: Decodable {
        var message: String
    }

    var error: Detail
}

public enum PingError: LocalizedError {
    case unreachable
    case rejected(status: Int, message: String)

    public var errorDescription: String? {
        switch self {
        case .unreachable: "Buzz could not reach the server"
        case let .rejected(_, message): message
        }
    }
}
