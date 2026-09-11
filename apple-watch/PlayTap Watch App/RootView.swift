import SwiftUI

/// Placeholder root screen for Phase 1A: no Score/Timer engine exists yet
/// (see docs/ROADMAP.md), so this honestly shows "no active session" rather
/// than a fake score or timer. Score/Timer entry points land here once the
/// Session Engine exists — see `playtap-watch-ux` for the interaction rules
/// this screen must keep respecting (huge text, high contrast, no clutter).
struct RootView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Text("PlayTap")
                    .font(.headline)
                    .foregroundStyle(.white)

                Text("No active session")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

#Preview {
    RootView()
}
