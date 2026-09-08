import Foundation

struct ConnectionIssue: Equatable {
    enum Kind { case offline, timeout, unavailable, rateLimited, expired }
    let kind: Kind

    init(kind: Kind) { self.kind = kind }

    init(_ error: Error) {
        if let error = error as? URLError {
            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
                kind = .offline
            case .timedOut: kind = .timeout
            default: kind = .unavailable
            }
        } else if case let PingError.rejected(status, _) = error {
            switch status {
            case 401, 403, 404: kind = .expired
            case 429: kind = .rateLimited
            default: kind = .unavailable
            }
        } else {
            kind = .unavailable
        }
    }

    var title: String {
        switch kind {
        case .offline: "You’re offline"
        case .timeout: "That took a little too long"
        case .unavailable: "Couldn’t connect"
        case .rateLimited: "Give it a moment"
        case .expired: "Let’s reconnect"
        }
    }

    var message: String {
        switch kind {
        case .offline: "Check your internet connection, then try again."
        case .timeout: "Buzz didn’t respond in time. Try connecting again."
        case .unavailable:
            PingEnvironment.host == PingEnvironment.local
                ? "Check that Tailscale is connected and Buzz is running on your Mac."
                : "Buzz is temporarily unavailable. Please try again in a moment."
        case .rateLimited: "There have been a few too many attempts. Try again shortly."
        case .expired: "This connection is no longer available. Reconnect to get a new code."
        }
    }

    var action: String { kind == .expired ? "Reconnect" : "Try Again" }
}
