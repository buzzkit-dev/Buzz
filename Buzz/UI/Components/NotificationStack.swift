import SwiftUI

struct NotificationStack: View {
    let slots: [SampleNotification]
    let arrived: Bool

    private static let tilts: [(rotation: Double, offset: CGFloat)] = [(-3, -10), (2, 12), (-2, -6)]

    var body: some View {
        VStack(spacing: 14) {
            ForEach(Array(slots.enumerated()), id: \.offset) { index, notification in
                let tilt = Self.tilts[index % Self.tilts.count]
                NotificationCard(notification: notification)
                    .id(notification.id)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                    .rotationEffect(.degrees(tilt.rotation))
                    .offset(x: tilt.offset)
                    .opacity(arrived ? 1 : 0)
                    .scaleEffect(arrived ? 1 : 0.85)
                    .offset(y: arrived ? 0 : 10)
                    .animation(Motion.entrance.delay(Double(index) * 0.12), value: arrived)
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.large)
        .accessibilityHidden(true)
    }
}

struct SwappingStack: View {
    let count: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var slots: [SampleNotification] = []
    @State private var arrived = false

    private static let interval: Duration = .seconds(3)

    var body: some View {
        NotificationStack(slots: slots, arrived: arrived || reduceMotion)
            .task(id: count) { await run() }
    }

    private func run() async {
        slots = Array(SampleNotification.pool.prefix(count))
        guard !reduceMotion else { return }

        try? await Task.sleep(for: .milliseconds(80))
        arrived = true

        var index = 0
        while !Task.isCancelled {
            try? await Task.sleep(for: Self.interval)
            guard !Task.isCancelled else { return }
            withAnimation(Motion.cardSwap) { swap(slot: index % slots.count) }
            index += 1
        }
    }

    private func swap(slot: Int) {
        let others = slots.enumerated().filter { $0.offset != slot }.map(\.element)
        let roomForRich = others.allSatisfy(\.isBanner)
        let shown = Set(slots.map(\.id))
        let candidates = SampleNotification.pool.filter { !shown.contains($0.id) && (roomForRich || $0.isBanner) }

        guard let next = candidates.randomElement() else { return }
        slots[slot] = next
    }
}

#Preview {
    SwappingStack(count: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.brand1)
}
