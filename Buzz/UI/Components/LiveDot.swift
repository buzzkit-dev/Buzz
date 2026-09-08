import SwiftUI

struct LiveDot: View {
  var tint: Color = Theme.green

  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var pulsing = false

  var body: some View {
    ZStack {
      Circle()
        .fill(tint.opacity(0.6))
        .scaleEffect(pulsing ? 2.6 : 1)
        .opacity(pulsing ? 0 : 0.6)
      Circle()
        .fill(tint)
    }
    .frame(width: 9, height: 9)
    .onAppear {
      guard !reduceMotion else { return }
      withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) { pulsing = true }
    }
  }
}

struct StatusPill: View {
  let label: String
  var tint: Color = Theme.green
  var isActive = true

  var body: some View {
    HStack(spacing: 8) {
      if isActive { LiveDot(tint: tint) }
      else { Circle().fill(tint).frame(width: 9, height: 9) }
      Text(label)
        .typo(FontSize.base, weight: .medium)
        .foregroundStyle(Theme.fg3)
    }
    .padding(.leading, 16)
    .padding(.trailing, 16)
    .frame(minHeight: 44)
    .background(Theme.bg2, in: .capsule)
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  VStack(spacing: 16) {
    StatusPill(label: "Listening")
    StatusPill(label: "Waiting on you", tint: Theme.amber)
  }
  .padding(24)
  .background(Theme.backgroundSubtle)
}
