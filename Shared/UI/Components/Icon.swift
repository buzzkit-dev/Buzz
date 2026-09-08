import SwiftUI

public struct Icon: View {
    private let name: String
    private let size: CGFloat

    public init(_ name: String, size: CGFloat = 18) {
        self.name = name
        self.size = size
    }

    public var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack(spacing: 16) {
        Icon("IconClipboard2").foregroundStyle(Theme.fg2)
        Icon("IconCheckmark1").foregroundStyle(Theme.green)
        Icon("IconQrCode").foregroundStyle(Theme.fg4)
    }
    .padding()
}
