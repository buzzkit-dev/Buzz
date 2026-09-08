import BuzzKit
import Foundation
import UserNotifications

private var debugLogging: Bool {
    #if DEBUG
        return true
    #else
        return false
    #endif
}

@MainActor
@Observable
final class PairingModel {
    enum Phase: Equatable {
        case loading
        case unpaired
        case paired
    }

    private(set) var isPreview = false
    var phase: Phase = .loading
    var endpoint: URL?
    var failure: ConnectionIssue?
    var isWorking = false

    var code: String?
    var codeExpiresAt: Date?
    var codeFailure: ConnectionIssue?

    var isRefreshingCode = false

    var notificationsDenied = false

    func restore() async {
        BuzzStore.selectEnvironment(host: PingClient.host)
        #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-BuzzAutoPair"), !BuzzStore.isPaired {
                await pair(provisional: true)
                return
            }
            if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewOffline") {
                isPreview = true
                phase = .unpaired
                failure = ConnectionIssue(kind: .offline)
                return
            }
            if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewError") {
                isPreview = true
                phase = .unpaired
                failure = ConnectionIssue(kind: .unavailable)
                return
            }
            if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewUnpaired") {
                phase = .unpaired
                return
            }
            if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewHome") {
                isPreview = true
                endpoint = Self.sampleEndpoint
                if !ProcessInfo.processInfo.arguments.contains("-BuzzPreviewConnecting") {
                    code = Self.sampleCode
                    codeExpiresAt = .now.addingTimeInterval(299)
                }
                notificationsDenied = ProcessInfo.processInfo.arguments.contains("-BuzzPreviewNotificationsOff")
                phase = .paired
                return
            }
        #endif

        guard BuzzStore.isPaired, let stored = BuzzStore.endpoint else {
            phase = .unpaired
            await pair()
            return
        }

        endpoint = stored
        phase = .paired
        await configureBuzzKit()
    }

    func pair(provisional: Bool = false, retried: Bool = false) async {
        guard !isWorking, !isPreview else { return }
        isWorking = true
        failure = nil
        defer { isWorking = false }

        do {
            let pairing = try await PingClient.pair()
            BuzzStore.endpoint = PingClient.host.appending(path: pairing.key)
            BuzzStore.identity = BuzzIdentity(
                apiURL: pairing.buzzkit.apiUrl,
                publishableKey: pairing.buzzkit.publishableKey,
                externalId: pairing.buzzkit.externalId,
                identityHash: pairing.buzzkit.identityHash
            )

            endpoint = BuzzStore.endpoint
            await configureBuzzKit()
            _ = try? await BuzzKit.registerForPush(provisional: provisional)
            phase = .paired
        } catch {
            if !retried {
                try? await Task.sleep(for: Self.retryDelay)
                isWorking = false
                await pair(provisional: provisional, retried: true)
                return
            }
            failure = ConnectionIssue(error)
        }
    }

    func rotate() async {
        guard !isPreview else { return }
        guard let client = PingClient.paired() else { return }
        isWorking = true
        failure = nil
        defer { isWorking = false }

        do {
            let rotation = try await client.rotate()
            BuzzStore.endpoint = rotation.endpoint
            endpoint = rotation.endpoint
            code = nil
            codeExpiresAt = nil
        } catch {
            failure = ConnectionIssue(error)
        }
    }

    func refreshCode() async {
        guard !isPreview, endpoint != nil, !isRefreshingCode else { return }
        isRefreshingCode = true
        defer { isRefreshingCode = false }
        #if DEBUG
            if endpoint == Self.sampleEndpoint { return }
        #endif
        guard let client = PingClient.paired() else { return }
        codeFailure = nil

        for attempt in 0..<Self.attempts {
            do {
                let minted = try await client.pairingCode()
                code = minted.code
                codeExpiresAt = .now.addingTimeInterval(TimeInterval(minted.expiresIn))
                recovery?.cancel()
                recovery = nil
                return
            } catch {
                let issue = ConnectionIssue(error)
                if issue.kind == .expired {
                    code = nil
                    codeExpiresAt = nil
                    isRefreshingCode = false
                    BuzzStore.clear()
                    endpoint = nil
                    await pair()
                    return
                }
                if attempt + 1 < Self.attempts {
                    try? await Task.sleep(for: Self.retryDelay)
                    continue
                }
                code = nil
                codeExpiresAt = nil
                codeFailure = issue
                scheduleRecovery()
            }
        }
    }

    private static let attempts = 4
    private static let retryDelay: Duration = .seconds(2)
    private static let recoveryDelay: Duration = .seconds(5)

    private var recovery: Task<Void, Never>?

    private func scheduleRecovery() {
        guard recovery == nil else { return }
        recovery = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: Self.recoveryDelay)
                guard !Task.isCancelled, let self else { return }
                if codeFailure == nil, failure == nil { recovery = nil; return }
                await retryConnection()
            }
        }
    }

    func retryConnection() async {
        guard !isPreview, !isWorking, !isRefreshingCode else { return }
        let expired = (failure ?? codeFailure)?.kind == .expired
        if endpoint == nil || expired {
            codeFailure = nil
            await pair()
        } else {
            await refreshCode()
        }
    }

    func reconnectIfNeeded() async {
        guard !isPreview else { return }
        if failure != nil || codeFailure != nil || code == nil || (codeExpiresAt ?? .distantPast) <= .now {
            await retryConnection()
        }
    }

    func refreshNotificationStatus() async {
        guard !isPreview else { return }
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        notificationsDenied = settings.authorizationStatus == .denied
    }

    private func configureBuzzKit() async {
        guard let identity = BuzzStore.identity else { return }

        if !BuzzKit.isConfigured {
            BuzzKit.configure(
                with: BuzzKit.Configuration(
                    apiKey: identity.publishableKey,
                    apiURL: identity.apiURL,
                    logLevel: debugLogging ? .debug : .warn,
                    appGroup: BuzzStore.appGroup
                )
            )
            BuzzKit.activities.observe(BuzzActivityAttributes.self)
            ActivityBinder.start()
        }
        BuzzKit.identify(identity.externalId, identityHash: identity.identityHash)
    }
}

#if DEBUG
    extension PairingModel {
        static let sampleEndpoint = URL(string: "https://ping.buzzkit.dev/bz_7fk2m9xq4p3wnd8vhs2kzq")
        static let sampleCode = "482913"

        static var pairedPreview: PairingModel {
            let model = PairingModel()
            model.isPreview = true
            model.endpoint = sampleEndpoint
            model.code = sampleCode
            model.codeExpiresAt = .now.addingTimeInterval(299)
            model.phase = .paired
            return model
        }
    }
#endif
