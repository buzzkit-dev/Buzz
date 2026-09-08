import SwiftUI

struct EndpointSheet: View {
  @Environment(PairingModel.self) private var pairing
  @Environment(\.sheetDismiss) private var dismiss
  @State private var isConfirmingRotate = false

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      VStack(alignment: .leading, spacing: 2) {
        Text("Your endpoint")
          .typo(FontSize.xl, weight: .medium)
          .foregroundStyle(Theme.fg4)
        Text("Anything with this URL can reach your phone. Rotate it if it leaks.")
          .typo(FontSize.base)
          .foregroundStyle(Theme.fg2)
          .fixedSize(horizontal: false, vertical: true)
      }

      if let endpoint = pairing.endpoint {
        EndpointField(url: endpoint)
      }

      if let failure = pairing.failure {
        Text(failure.message).typo(FontSize.base).foregroundStyle(Theme.fg2)
      }

      AppButton(title: "Done", variant: .primary) { dismiss() }

      AppButton(title: "Rotate endpoint", variant: .secondary, disabled: pairing.isWorking || pairing.isPreview) {
        isConfirmingRotate = true
      }
    }
    .padding(.horizontal, 20)
    .padding(.top, 24)
    .padding(.bottom, 20)
    .alert("Rotate this endpoint?", isPresented: $isConfirmingRotate) {
      Button("Cancel", role: .cancel) {}
      Button("Rotate endpoint", role: .destructive) {
        Task {
          await pairing.rotate()
          if pairing.failure == nil { dismiss() }
        }
      }
    } message: {
      Text(
        "The current URL stops working right away, every connected agent is disconnected, and your notifications and activity are cleared. Connect again with a new code to start fresh. This cannot be undone."
      )
    }
  }
}

#Preview {
  EndpointSheet()
    .environment(PairingModel.pairedPreview)
    .background(Theme.background)
}
