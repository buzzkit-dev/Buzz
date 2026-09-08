import CryptoKit
import UIKit

public enum AvatarStore {
    private static let side: CGFloat = 256
    private static let maxBytes = 2_000_000

    private static var directory: URL? {
        guard
            let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: BuzzStore.appGroup)
        else { return nil }
        let directory = container.appending(path: "avatars", directoryHint: .isDirectory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private static func file(for source: String) -> URL? {
        guard !source.isEmpty else { return nil }
        let digest = SHA256.hash(data: Data(source.utf8)).map { String(format: "%02x", $0) }.joined()
        return directory?.appending(path: "\(digest).png")
    }

    public static func image(for source: String?) -> UIImage? {
        guard let source, let file = file(for: source), let data = try? Data(contentsOf: file) else { return nil }
        return UIImage(data: data)
    }

    public static func warm(_ source: String?) async {
        guard
            let source,
            let remote = URL(string: source),
            remote.scheme == "https",
            let file = file(for: source),
            !FileManager.default.fileExists(atPath: file.path)
        else { return }

        var request = URLRequest(url: remote)
        request.timeoutInterval = 15
        guard
            let (data, response) = try? await URLSession.shared.data(for: request),
            (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) ?? false,
            data.count <= maxBytes,
            let downsized = downsize(data)
        else { return }

        try? downsized.write(to: file, options: .atomic)
    }

    private static func downsize(_ data: Data) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }
        return rendered.pngData()
    }
}
