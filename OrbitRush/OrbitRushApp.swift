import SwiftUI

@main
struct OrbitRushApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
                .preferredColorScheme(.dark)
        }
    }
}

private struct AppRootView: View {
    @State private var isReady = false

    var body: some View {
        ZStack {
            GameView()
                .opacity(isReady ? 1 : 0)

            if !isReady {
                LaunchView()
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(1.55))
            withAnimation(.easeOut(duration: 0.28)) {
                isReady = true
            }
        }
    }
}
