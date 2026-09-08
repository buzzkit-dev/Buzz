import Foundation

public enum BuzzStore {
    public static let appGroup = "group.studio.overclock.buzz"

    private enum Key {
        static var endpoint: String { "buzz.endpoint" + scope }
        static var externalId: String { "buzz.externalId" + scope }
        static var identityHash: String { "buzz.identityHash" + scope }
        static var publishableKey: String { "buzz.publishableKey" + scope }
        static var apiURL: String { "buzz.apiURL" + scope }
    }

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroup)
    }

    private static var scope: String { defaults?.string(forKey: "buzz.activeScope") ?? "" }

    public static func selectEnvironment(host: URL) {
        let scope = host.absoluteString == "https://ping.buzzkit.dev" ? "" : "." + host.absoluteString
        defaults?.set(scope, forKey: "buzz.activeScope")
    }

    public static var endpoint: URL? {
        get {
            guard let raw = defaults?.string(forKey: Key.endpoint) else { return nil }
            return URL(string: raw)
        }
        set { defaults?.set(newValue?.absoluteString, forKey: Key.endpoint) }
    }

    public static var identity: BuzzIdentity? {
        get {
            guard
                let store = defaults,
                let externalId = store.string(forKey: Key.externalId),
                let publishableKey = store.string(forKey: Key.publishableKey),
                let apiURL = store.string(forKey: Key.apiURL).flatMap(URL.init(string:))
            else { return nil }

            return BuzzIdentity(
                apiURL: apiURL,
                publishableKey: publishableKey,
                externalId: externalId,
                identityHash: store.string(forKey: Key.identityHash)
            )
        }
        set {
            guard let store = defaults else { return }
            store.set(newValue?.externalId, forKey: Key.externalId)
            store.set(newValue?.identityHash, forKey: Key.identityHash)
            store.set(newValue?.publishableKey, forKey: Key.publishableKey)
            store.set(newValue?.apiURL.absoluteString, forKey: Key.apiURL)
        }
    }

    public static var isPaired: Bool {
        endpoint != nil && identity != nil
    }

    public static func clear() {
        endpoint = nil
        identity = nil
    }
}

public struct BuzzIdentity: Sendable, Equatable {
    public var apiURL: URL
    public var publishableKey: String
    public var externalId: String
    public var identityHash: String?
}
