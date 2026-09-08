import SwiftUI

public extension BuzzStatus {
    var tint: Color {
        switch self {
        case .working: Theme.sky
        case .waiting: Theme.amber
        case .done: Theme.green
        case .failed: Theme.red
        }
    }

    var icon: String {
        switch self {
        case .working: "IconCircleDashedFilled"
        case .waiting: "IconRaisingHand5FingerFilled"
        case .done: "IconCircleCheckFilled"
        case .failed: "IconExclamationTriangleFilled"
        }
    }
}

public struct StatusIcon: View {
    private let status: BuzzStatus
    private let size: CGFloat

    public init(_ status: BuzzStatus, size: CGFloat = 18) {
        self.status = status
        self.size = size
    }

    public var body: some View {
        Icon(status.icon, size: size)
            .foregroundStyle(status.tint)
    }
}

public struct ProgressBar: View {
    private let fraction: Double
    private let tint: Color

    public init(fraction: Double, tint: Color) {
        self.fraction = fraction
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.inkForeground.opacity(0.14))
                Capsule()
                    .fill(tint)
                    .frame(width: max(4, proxy.size.width * min(1, max(0, fraction))))
            }
        }
        .frame(height: 4)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(alignment: .leading, spacing: 16) {
        HStack(spacing: 12) {
            ForEach([BuzzStatus.working, .waiting, .done, .failed], id: \.self) { status in
                StatusIcon(status, size: 20)
            }
        }
        ProgressBar(fraction: 0.43, tint: BuzzStatus.working.tint)
    }
    .padding(24)
    .background(Theme.ink)
}
