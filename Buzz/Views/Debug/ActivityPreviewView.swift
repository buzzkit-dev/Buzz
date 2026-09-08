import ActivityKit
import SwiftUI

struct ActivityPreviewView: View {
    private let samples: [(String, BuzzActivityAttributes.ContentState)] = [
        ("One agent", BuzzSamples.single),
        ("Several agents", BuzzSamples.many),
        ("Waiting on you", BuzzSamples.waiting),
    ]

    private let shape = RoundedRectangle(cornerRadius: Theme.Radius.notification, style: .continuous)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(samples, id: \.0) { name, state in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(name)
                                .typo(FontSize.xs)
                                .foregroundStyle(Theme.inkForeground.opacity(0.6))
                                .padding(.leading, 4)

                            LockScreenView(state: state)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Theme.ink, in: shape)
                                .overlay(shape.strokeBorder(Theme.inkForeground.opacity(0.1), lineWidth: 1))

                            AppButton(title: "Start as a real activity", variant: .ghost) {
                                start(state)
                            }
                            .padding(.leading, -6)
                        }
                    }
                }
                .padding(24)
            }
            .scrollIndicators(.hidden)
            .background(LinearGradient(colors: [Color(white: 0.11), .black], startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            .navigationTitle("Live Activity")
            .navigationBarTitleDisplayMode(.inline)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains("-BuzzStartPreviewActivity") { start(BuzzSamples.waiting) }
        }
    }

    private func start(_ state: BuzzActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        for activity in Activity<BuzzActivityAttributes>.activities {
            let boxed = Unchecked(activity)
            Task { await boxed.value.end(nil, dismissalPolicy: .immediate) }
        }

        _ = try? Activity.request(
            attributes: BuzzActivityAttributes(),
            content: .init(state: state, staleDate: nil)
        )
    }
}

#Preview {
    ActivityPreviewView()
}
