import SwiftUI

@main
struct BuzzApp: App {
    @State private var pairing = PairingModel()
    @State private var activities = ActivityMonitor()
    #if DEBUG
        @State private var timeline = TimelineModel.launch()
    #else
        @State private var timeline = TimelineModel()
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(pairing)
                .environment(activities)
                .environment(timeline)
                .task {
                    await pairing.restore()
                    activities.start()
                    await timeline.refresh()
                }
        }
    }
}
