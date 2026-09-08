import SwiftUI

struct HomeView: View {
  @Environment(PairingModel.self) private var pairing
  @Environment(ActivityMonitor.self) private var activities
  @Environment(TimelineModel.self) private var timeline
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.openURL) private var openURL
  @State private var isShowingEndpoint = false
  @State private var copies = 0
  @State private var copied = false
  @State private var stageHeight: CGFloat = 0
  @State private var isConfirmingClear = false
  #if DEBUG
  @State private var isShowingScreenPreview = false
  #endif

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
          HStack {
            StatusPill(label: statusLabel, tint: statusTint, isActive: connectionIssue == nil && pairing.endpoint != nil)
            Spacer()
            Menu {
              Button("About Buzz", systemImage: "info.circle") { openURL(URL(string: "https://buzzkit.dev/buzz")!) }
              Button("Show endpoint", systemImage: "link") { isShowingEndpoint = true }
                .disabled(pairing.endpoint == nil)
              Button("Clear notifications", systemImage: "trash", role: .destructive) { isConfirmingClear = true }
                .tint(timeline.hasEvents ? Theme.redText : nil)
                .disabled(!timeline.hasEvents)
              #if DEBUG
              if pairing.isPreview {
                Button("Show Idle Preview") { activities.state = nil }
                Button("Show Working Preview") { activities.state = BuzzSamples.many }
                Button("Show Waiting Preview") { activities.state = BuzzSamples.waiting }
                Button(pairing.notificationsDenied ? "Show Notifications On Preview" : "Show Notifications Off Preview") {
                  pairing.notificationsDenied.toggle()
                }
                Button(pairing.code == nil ? "Show Code Preview" : "Show Connecting Preview") {
                  pairing.code = pairing.code == nil ? PairingModel.sampleCode : nil
                }
                Button(timeline.hasEvents ? "Show Sample Stack Preview" : "Show Timeline Preview") {
                  timeline.showPreviewSamples(!timeline.hasEvents)
                }
                if pairing.failure == nil {
                  Button("Show Offline Preview") { pairing.failure = ConnectionIssue(kind: .offline) }
                  Button("Show Connection Error Preview") { pairing.failure = ConnectionIssue(kind: .unavailable) }
                } else {
                  Button("Show Connected Preview") { pairing.failure = nil }
                }
              } else {
                Button("Preview Screens") { isShowingScreenPreview = true }
              }
              #endif
            } label: {
              Icon("IconDotGrid1x3HorizontalFilled", size: 22)
                .foregroundStyle(Theme.fg2)
                .frame(width: 44, height: 44)
                .background(Theme.bg2, in: .circle)
            }
            .buttonStyle(PressButtonStyle())
            .accessibilityLabel("More")
          }
      .padding(.top, 8)

          Stage(muted: isStageMuted) {
            if let issue = connectionIssue, !timeline.hasEvents, activities.state == nil {
              StageNotice.connection(issue, loading: pairing.isWorking || pairing.isRefreshingCode) {
                Task { await pairing.retryConnection() }
              }
              .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else if pairing.notificationsDenied {
              StageNotice.notificationsOff()
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
              ZStack {
                TimelineFeed()
                if !timeline.hasEvents, activities.state == nil {
                  SwappingStack(count: stageHeight < 340 ? 1 : 2)
                    .transition(.opacity)
                }
              }
              .animation(Motion.swap, value: timeline.hasEvents || activities.state != nil)
              .transition(.opacity)
            }
          }
          .frame(maxHeight: .infinity)
          .frame(minHeight: 160)
      .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { stageHeight = $0 }
      .animation(Motion.swap, value: stageIdentity)
      .padding(.top, 16)

      connectSection
    }
    .padding(.horizontal, 24)
    .padding(.bottom, 16)
    .dynamicTypeSize(...DynamicTypeSize.xLarge)
    .background(Theme.background.ignoresSafeArea())
    .alert("Clear all notifications?", isPresented: $isConfirmingClear) {
      Button("Cancel", role: .cancel) {}
      Button("Clear", role: .destructive) { Task { await timeline.clear() } }
    } message: {
      Text("This clears everything from your timeline. This cannot be undone.")
    }
    .customSheet(isPresented: $isShowingEndpoint) {
      EndpointSheet().environment(pairing)
    }
    #if DEBUG
    .sheet(isPresented: $isShowingScreenPreview) {
      ScreenPreviewView()
    }
    #endif
    .task(id: copies) {
      guard copies > 0 else { return }
      do { try await Task.sleep(for: .seconds(2)) } catch { return }
      copied = false
    }
    .task { await pairing.refreshNotificationStatus() }
    .task(id: pairing.endpoint) { await pairing.refreshCode() }
    .task(id: pairing.codeExpiresAt) {
      guard let expiresAt = pairing.codeExpiresAt else { return }
      try? await Task.sleep(for: .seconds(max(1, expiresAt.timeIntervalSinceNow)))
      guard !Task.isCancelled else { return }
      await pairing.refreshCode()
    }
    .onChange(of: pairing.endpoint) { previous, current in
      guard previous != nil, current != previous else { return }
      timeline.forget()
      Task { await activities.reconcile() }
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      Task {
        await pairing.refreshNotificationStatus()
        await pairing.reconnectIfNeeded()
        await timeline.refresh()
        await activities.reconcile()
      }
    }
    .onAppear {
      #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-BuzzPreviewEndpoint") {
          isShowingEndpoint = true
        }
      #endif
    }
  }

  private var connectSection: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading, spacing: 2) {
        Text(timeline.hasConnected ? "Connect another agent" : "Connect an agent")
          .typo(FontSize.xxl, weight: .medium)
          .foregroundStyle(Theme.fg4)
          .contentTransition(.numericText())
          .animation(Motion.swap, value: timeline.hasConnected)
        Text("Give this code to your coding agent, or copy the setup message.")
          .typo(FontSize.base)
          .foregroundStyle(Theme.fg2)
      }
      .padding(.top, 24)

      CodeDigits(code: pairing.code)
        .padding(.top, 24)

      AppButton(
          title: actionTitle,
          icon: copied ? "IconCheckmark1" : "IconClipboard2",
          iconColor: copied ? Theme.green : Theme.primaryForeground.opacity(0.6),
          size: .lg,
          loading: connectionIssue == nil && pairing.code == nil,
          disabled: connectionIssue != nil
        ) {
          guard let code = pairing.code else { return }
          UIPasteboard.general.string =
            "Install and set up Buzz: \(PingClient.host.appending(path: "skill.md").absoluteString) with pairing code \(code)"
          copies += 1
          copied = true
        }
      .padding(.top, 27)
    }
  }

  private var connectionIssue: ConnectionIssue? { pairing.failure ?? pairing.codeFailure }

  private var isStageMuted: Bool { (connectionIssue != nil && !timeline.hasEvents && activities.state == nil) || pairing.notificationsDenied }

  private var stageIdentity: String {
    if connectionIssue != nil, !timeline.hasEvents, activities.state == nil { return "issue" }
    if pairing.notificationsDenied { return "muted" }
    return "feed"
  }

  private var actionTitle: String {
    if connectionIssue == nil, pairing.code == nil { return "Connecting…" }
    return copied ? "Copied Setup Message" : "Copy Setup Message"
  }

  private var statusLabel: String {
    if let issue = connectionIssue { return issue.kind == .offline ? "Offline" : "Not connected" }
    if pairing.isPreview { return "Preview" }
    guard pairing.endpoint != nil else { return "Connecting" }
    guard let state = activities.state else { return "Listening" }
    if state.waiting > 0 { return "Waiting on you" }
    if state.live > 1 { return "\(state.live) agents working" }
    return "1 agent working"
  }

  private var statusTint: Color {
    if connectionIssue != nil { return Theme.amber }
    if pairing.endpoint == nil { return Theme.fg2 }
    guard let state = activities.state else { return Theme.green }
    return state.waiting > 0 ? Theme.amber : Theme.sky
  }
}

#Preview("Idle") {
  HomeView()
    .environment(PairingModel.pairedPreview)
    .environment(ActivityMonitor.idlePreview)
    .environment(TimelineModel.emptyPreview)
}

#Preview("Timeline") {
  HomeView()
    .environment(PairingModel.pairedPreview)
    .environment(ActivityMonitor.livePreview)
    .environment(TimelineModel.samplePreview)
}

#Preview("Notifications off") {
  let model = PairingModel.pairedPreview
  model.notificationsDenied = true
  return HomeView()
    .environment(model)
    .environment(ActivityMonitor.idlePreview)
    .environment(TimelineModel.emptyPreview)
}
