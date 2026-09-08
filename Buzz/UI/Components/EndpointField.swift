import SwiftUI
import UIKit

struct EndpointField: View {
    let url: URL

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var copied = false
    @State private var copies = 0

    private let shape = Capsule()

    var body: some View {
        Button(action: copy) {
            HStack(spacing: 12) {
                label
                    .typo(FontSize.base, weight: .medium)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if copied {
                        Icon("IconCheckmark1", size: 20)
                            .foregroundStyle(Theme.green)
                            .transition(reduceMotion ? .opacity : .buttonLabelScaleBlur)
                    } else {
                        Icon("IconClipboard2", size: 20)
                            .foregroundStyle(Theme.fg2)
                            .transition(reduceMotion ? .opacity : .buttonLabelScaleBlur)
                    }
                }
                .frame(width: 20, height: 20)
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: copied)
            }
            .padding(.horizontal, 20)
            .frame(minHeight: 54)
            .background(Theme.bg2, in: shape)
            .contentShape(shape)
        }
        .buttonStyle(PressButtonStyle(pressedScale: 1))
        .accessibilityLabel(copied ? "Copied" : "Copy endpoint \(url.absoluteString)")
        .task(id: copies) {
            guard copies > 0 else { return }
            try? await Task.sleep(for: .seconds(1.5))
            copied = false
        }
    }

    private var label: Text {
        var host = url.host() ?? ""
        if let port = url.port { host += ":\(port)" }
        return Text(host).foregroundStyle(Theme.fg2) + Text(url.path()).foregroundStyle(Theme.fg4)
    }

    private func copy() {
        UIPasteboard.general.string = url.absoluteString
        copied = true
        copies += 1
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: 16) {
        EndpointField(url: URL(string: "https://ping.buzzkit.dev/bz_7fk2m9xq4p3wnd8vhs2kzq")!)
        EndpointField(url: URL(string: "http://100.102.32.85:8792/bz_7fk2m9xq4p3wnd8vhs2kzq")!)
    }
    .padding(24)
}
