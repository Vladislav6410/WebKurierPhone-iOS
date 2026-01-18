import SwiftUI

@main
struct WebKurierPhoneApp: App {

    @StateObject private var localizationManager = LocalizationManager()
    @StateObject private var coreGateway = CoreGateway.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(localizationManager)
                .environmentObject(coreGateway)
        }
    }
}

struct RootView: View {

    @EnvironmentObject private var coreGateway: CoreGateway

    var body: some View {
        Group {
            if coreGateway.isAuthenticated {
                MainTabView()
            } else {
                LoadingView()
            }
        }
        .onAppear {
            coreGateway.bootstrap()

            // ✅ Keep backward compatibility with older MediaCleaner bootstrapping
            coreGateway.configureMediaCleanerAPI()
        }
    }
}

struct MainTabView: View {

    var body: some View {
        TabView {

            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            TranslatorView()
                .tabItem { Label("Translate", systemImage: "globe") }

            VoiceCallView()
                .tabItem { Label("Call", systemImage: "phone") }

            LessonsView()
                .tabItem { Label("Lessons", systemImage: "graduationcap") }

            WalletView()
                .tabItem { Label("Wallet", systemImage: "wallet.pass") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 10) {
            ProgressView()
            Text("Connecting…")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}