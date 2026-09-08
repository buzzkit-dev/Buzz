#if DEBUG
import SwiftUI

struct ScreenPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pairing = PairingModel.pairedPreview
    @State private var activities = ActivityMonitor.idlePreview
    @State private var timeline = TimelineModel.samplePreview

    var body: some View {
        NavigationStack {
            HomeView()
                .environment(pairing)
                .environment(timeline)
                .environment(activities)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }
}

#Preview {
    ScreenPreviewView()
}
#endif
