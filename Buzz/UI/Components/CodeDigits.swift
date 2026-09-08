import SwiftUI

struct CodeDigits: View {
  let code: String?

  private let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)

  var body: some View {
    HStack(spacing: 8) {
      ForEach(0..<6, id: \.self) { index in
        tile(at: index)
        if index == 2 {
          Spacer().frame(width: 8)
        }
      }
    }
    .animation(Motion.swap, value: code)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(
      code.map { "Pairing code \($0.map(String.init).joined(separator: " "))" }
        ?? "No pairing code yet")
  }

  private func tile(at index: Int) -> some View {
    let digit = code.flatMap {
      $0.count == 6 ? String($0[$0.index($0.startIndex, offsetBy: index)]) : nil
    }

    return Text(digit ?? "·")
      .typo(FontSize.xxxl, weight: .medium)
      .monospacedDigit()
      .foregroundStyle(digit == nil ? Theme.fg1 : Theme.fg4)
      .contentTransition(.numericText())
      .frame(maxWidth: .infinity)
      .frame(height: 64)
      .background(Theme.bg2, in: shape)
  }
}

#Preview(traits: .sizeThatFitsLayout) {
  VStack(spacing: 24) {
    CodeDigits(code: "482913")
    CodeDigits(code: nil)
  }
  .padding(24)
  .background(Theme.backgroundSubtle)
}
