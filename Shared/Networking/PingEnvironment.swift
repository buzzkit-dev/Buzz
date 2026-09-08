import Foundation

public enum PingEnvironment {
    public static let production = URL(string: "https://ping.buzzkit.dev")!
    public static let local = URL(string: "http://100.102.32.85:8792")!

    public static var host: URL {
        #if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let raw = environment["BUZZ_PING_URL"], let url = URL(string: raw) { return url }
        return environment["BUZZ_PING_ENV"] == "production" ? production : local
        #else
        return production
        #endif
    }
}
