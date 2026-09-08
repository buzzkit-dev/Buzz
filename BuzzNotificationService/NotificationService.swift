import BuzzKit
import BuzzKitNotificationServiceExtension
import Intents
import UIKit
import UserNotifications

final class NotificationService: BuzzKitNotificationService {
    override var buzzKitAppGroup: String? { BuzzStore.appGroup }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        let sender = Self.resolveSender(request.content.userInfo)
        Self.warmAvatar(request.content.userInfo)
        super.didReceive(request) { content in
            contentHandler(Self.decorate(content, sender: sender))
        }
    }

    private static func fields(_ userInfo: [AnyHashable: Any]) -> (agent: String?, avatar: String?) {
        guard let payload = PushPayload(userInfo: userInfo) else { return (nil, nil) }
        var agent: String?
        if case let .string(value)? = payload.data["agent"] { agent = value }
        var avatar: String?
        if case let .string(value)? = payload.data["avatar"] { avatar = value }
        return (agent, avatar)
    }

    private static func warmAvatar(_ userInfo: [AnyHashable: Any]) {
        let avatar = fields(userInfo).avatar
        guard avatar != nil, AvatarStore.image(for: avatar) == nil else { return }
        Task.detached { await AvatarStore.warm(avatar) }
    }

    private static func resolveSender(
        _ userInfo: [AnyHashable: Any]
    ) -> (label: String, image: Data, id: String)? {
        let (agent, avatar) = fields(userInfo)

        let image = AvatarStore.image(for: avatar)?.pngData() ?? agent.flatMap { AgentLabel.image(for: $0)?.pngData() }
        guard let image else { return nil }

        let id = (agent ?? avatar ?? "agent").lowercased()
        return (agent.map(AgentLabel.resolve) ?? "Agent", image, id)
    }

    private static func decorate(
        _ content: UNNotificationContent,
        sender: (label: String, image: Data, id: String)?
    ) -> UNNotificationContent {
        guard let sender else { return content }
        let image = sender.image

        let person = INPerson(
            personHandle: INPersonHandle(value: sender.id, type: .unknown),
            nameComponents: nil,
            displayName: sender.label,
            image: INImage(imageData: image),
            contactIdentifier: nil,
            customIdentifier: sender.id
        )
        let intent = INSendMessageIntent(
            recipients: nil,
            outgoingMessageType: .outgoingMessageText,
            content: content.body,
            speakableGroupName: nil,
            conversationIdentifier: sender.id,
            serviceName: "Buzz",
            sender: person,
            attachments: nil
        )
        let interaction = INInteraction(intent: intent, response: nil)
        interaction.direction = .incoming
        interaction.donate(completion: nil)

        guard let updated = try? content.updating(from: intent).mutableCopy() as? UNMutableNotificationContent
        else { return content }
        updated.subtitle = content.title
        return updated
    }
}
