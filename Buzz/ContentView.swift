import SwiftUI

struct ContentView: View {
    var body: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewActivity") {
            ActivityPreviewView()
        } else {
            home
        }
        #else
        home
        #endif
    }

    private var home: some View {
        HomeView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.background.ignoresSafeArea())
            .tint(Theme.fg4)
    }
}

#Preview {
    ContentView()
        .environment(PairingModel.pairedPreview)
        .environment(ActivityMonitor.idlePreview)
        .environment(TimelineModel.samplePreview)
}
