import SwiftUI

struct AppButton: View {
  enum Variant {
    case primary
    case secondary
    case ghost

    var textColor: Color {
      switch self {
      case .primary: Theme.primaryForeground
      case .secondary: Theme.fg3
      case .ghost: Theme.fg2
      }
    }

    var backgroundColor: Color {
      switch self {
      case .primary: Theme.primary
      case .secondary: Theme.bg2
      case .ghost: .clear
      }
    }
  }

  enum Size {
    case sm, md, lg

    var height: CGFloat {
      switch self {
      case .sm: 38
      case .md: 50
      case .lg: 54
      }
    }

    var horizontalPadding: CGFloat {
      switch self {
      case .sm: 16
      case .md: 20
      case .lg: 24
      }
    }

    var textSize: CGFloat {
      switch self {
      case .sm: FontSize.sm
      case .md: FontSize.xl
      case .lg: 22
      }
    }

    var leadingSize: CGFloat {
      switch self {
      case .sm: 14
      case .md, .lg: 20
      }
    }
  }

  var title: String?
  var icon: String?
  var iconColor: Color?
  var iconSize: CGFloat?
  var variant: Variant = .primary
  var size: Size = .md
  var haptic = true
  var loading = false
  var disabled = false
  var fullWidth = true
  let action: () -> Void

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private var isDisabled: Bool { disabled || loading }
  private var hasLeading: Bool { loading || icon != nil }
  private var leadingIdentity: String {
    if loading { return "loading" }
    if let icon { return "icon-\(icon)" }
    return "none"
  }

  var body: some View {
    Button(action: action) {
      content
    }
    .buttonStyle(PressButtonStyle(haptic: haptic, pressedScale: 0.975))
    .disabled(isDisabled)
    .opacity(isDisabled ? 0.5 : 1)
    .animation(.linear(duration: 0.18), value: isDisabled)
  }

  private var content: some View {
    HStack(spacing: hasLeading && title != nil ? 8 : 0) {
      if hasLeading {
        leading
          .transition(reduceMotion ? .opacity : .buttonLabelScaleBlur)
      }
      if let title {
        InterpolatedButtonLabel(title: title, fontSize: size.textSize, color: variant.textColor)
      }
    }
    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: leadingIdentity)
    .padding(.horizontal, size.horizontalPadding)
    .frame(minHeight: size.height)
    .frame(maxWidth: fullWidth ? .infinity : nil)
    .background(backgroundStyle, in: shape)
    .clipShape(shape)
    .contentShape(shape)
    .geometryGroup()
    .frame(minWidth: 44, minHeight: 44)
    .contentShape(.rect)
  }

  @ViewBuilder
  private var leading: some View {
    ZStack {
      if loading {
        Spinner(size: (iconSize ?? size.leadingSize + 4) - 4, color: variant.textColor)
          .id("loading")
          .transition(reduceMotion ? .opacity : .buttonLabelScaleBlur)
      } else if let icon {
        Icon(icon, size: iconSize ?? size.leadingSize + 4)
          .foregroundStyle(iconColor ?? variant.textColor)
          .id(leadingIdentity)
          .transition(reduceMotion ? .opacity : .buttonLabelScaleBlur)
      }
    }
    .frame(width: size.leadingSize + 4, height: size.leadingSize + 4)
    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: leadingIdentity)
  }

  private var backgroundStyle: AnyShapeStyle {
    AnyShapeStyle(variant.backgroundColor)
  }

  private var shape: RoundedRectangle {
    RoundedRectangle(cornerRadius: size.height / 2, style: .continuous)
  }
}

struct InterpolatedButtonLabel: View {
  var title: String
  var fontSize: CGFloat
  var color: Color

  var body: some View {
    Text(title)
      .font(.typo(fontSize, weight: .semibold))
      .tracking(fontSize * -0.02)
      .foregroundStyle(color)
      .lineLimit(2)
      .multilineTextAlignment(.center)
      .minimumScaleFactor(0.85)
      .contentTransition(.numericText())
      .animation(.snappy(duration: 0.24, extraBounce: 0), value: title)
      .fixedSize(horizontal: false, vertical: true)
  }
}

private struct ButtonLabelScaleBlurModifier: ViewModifier {
  let isIdentity: Bool

  func body(content: Content) -> some View {
    content
      .opacity(isIdentity ? 1 : 0)
      .scaleEffect(isIdentity ? 1 : 0.75)
      .blur(radius: isIdentity ? 0 : 2)
  }
}

extension AnyTransition {
  @MainActor static let buttonLabelScaleBlur = AnyTransition.modifier(
    active: ButtonLabelScaleBlurModifier(isIdentity: false),
    identity: ButtonLabelScaleBlurModifier(isIdentity: true)
  )
}

struct PressButtonStyle: ButtonStyle {
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  var haptic = true
  var pressedScale: CGFloat = 0.975

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1)
      .animation(.spring(response: 0.25, dampingFraction: 0.8), value: configuration.isPressed)
      .sensoryFeedback(.impact(weight: .light), trigger: configuration.isPressed) { _, isDown in
        haptic && isDown
      }
  }
}

#Preview {
  VStack(spacing: 16) {
    AppButton(title: "Get started") {}
    AppButton(title: "Creating", loading: true) {}
    AppButton(title: "Show endpoint", icon: "IconClipboard2", variant: .secondary) {}
    HStack {
      AppButton(title: "Try again", variant: .secondary, size: .sm, fullWidth: false) {}
      AppButton(title: "Open Settings", variant: .ghost, size: .sm, fullWidth: false) {}
    }
  }
  .padding(24)
  .background(Theme.background)
}
