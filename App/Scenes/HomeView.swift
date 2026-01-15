import SwiftUI

struct HomeView: View {

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    NavigationLink(destination: TranslatorView()) {
                        AgentTile(
                            title: "Translator",
                            subtitle: "Text & Voice Translation",
                            systemImage: "globe"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: VoiceCallView()) {
                        AgentTile(
                            title: "Voice Call",
                            subtitle: "Realtime bilingual calls",
                            systemImage: "phone"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: LessonsView()) {
                        AgentTile(
                            title: "Lessons",
                            subtitle: "Language practice A1–C1",
                            systemImage: "graduationcap"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: DreamMakerView()) {
                        AgentTile(
                            title: "DreamMaker",
                            subtitle: "Generate & preview media",
                            systemImage: "sparkles"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink(destination: WalletView()) {
                        AgentTile(
                            title: "Wallet",
                            subtitle: "WebCoin balance & history",
                            systemImage: "wallet.pass"
                        )
                    }
                    .buttonStyle(.plain)

                    // ✅ NEW: MediaCleaner (SmartSort)
                    NavigationLink(destination: MediaCleanerView()) {
                        AgentTile(
                            title: "MediaCleaner",
                            subtitle: "Cleanup duplicates, blur, screenshots",
                            systemImage: "wand.and.stars"
                        )
                    }
                    .buttonStyle(.plain)

                }
                .padding()
            }
            .navigationTitle("WebKurier")
        }
    }
}
