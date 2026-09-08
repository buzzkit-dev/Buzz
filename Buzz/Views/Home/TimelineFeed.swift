import SwiftUI

struct TimelineFeed: View {
    @Environment(TimelineModel.self) private var timeline
    @Environment(ActivityMonitor.self) private var activities

    private let shape = RoundedRectangle(cornerRadius: Theme.Radius.notification, style: .continuous)

    private var visibleEvents: [TimelineEvent] {
        guard let sessions = activities.state?.sessions else { return timeline.events }
        return timeline.events.filter { event in
            guard event.kind == .session, let id = event.session, let status = event.buzzStatus else { return true }
            return !sessions.contains { $0.id == id && $0.state == status }
        }
    }

    private var warmURLs: [String] {
        Array(Set(timeline.events.compactMap(\.avatar) + (activities.state?.sessions.compactMap(\.avatar) ?? [])))
    }

    private var warmKey: String { warmURLs.sorted().joined(separator: "|") }

    var body: some View {
        ScrollViewReader { reader in
        ScrollView {
            VStack(spacing: 0) {
            Color.clear.frame(height: 16).id("top")
            LazyVStack(spacing: 12) {
                if let state = activities.state {
                    LockScreenView(state: state)
                        .background(Theme.ink, in: shape)
                        .overlay(shape.strokeBorder(Theme.inkForeground.opacity(0.08), lineWidth: 1))
                        .shadow(color: Theme.shadow.opacity(0.5), radius: 7, y: 6)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        .animation(.snappy(duration: 0.4), value: state)
                        .zIndex(1)
                }
                ForEach(visibleEvents) { event in
                    TimelineCard(event: event)
                        .id(event.id)
                        .geometryGroup()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)
            .animation(Motion.swap, value: visibleEvents.map(\.id))
            .animation(Motion.swap, value: activities.state == nil)
            Color.clear.frame(height: 16)
            }
        }
        .scrollIndicators(.hidden)
        .refreshable { await timeline.refresh() }
        .mask {
            VStack(spacing: 0) {
                LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    .frame(height: 12)
                Color.black
                LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 20)
            }
        }
        .task(id: warmKey) {
            for url in warmURLs { await AvatarStore.warm(url) }
        }
        .task { await timeline.listen() }
        .task {
            await activities.reconcile()
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                guard !Task.isCancelled else { return }
                await timeline.refresh()
                await activities.reconcile()
            }
        }
        .onChange(of: timeline.events) { _, _ in
            Task { await activities.reconcile() }
        }
        .onChange(of: activities.state) { _, _ in
            Task { await timeline.refresh() }
        }
        .onChange(of: visibleEvents.first?.id) { _, first in
            guard first != nil else { return }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(50))
                withAnimation(Motion.swap) { reader.scrollTo("top", anchor: .top) }
            }
        }
        }
    }
}

#Preview {
    Stage {
        TimelineFeed()
    }
    .frame(height: 520)
    .padding(24)
    .environment(TimelineModel.samplePreview)
    .environment(ActivityMonitor.livePreview)
}
