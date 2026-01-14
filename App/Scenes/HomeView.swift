import SwiftUI

struct HomeView: View {

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {

                    AgentTile(
                        title: "Translator",
                        subtitle: "Text & Voice Translation",
                        systemImage: "globe"
                    )

                    AgentTile(
                        title: "Voice Call",
                        subtitle: "Realtime bilingual calls",
                        systemImage: "phone"
                    )

                    AgentTile(
                        title: "Lessons",
                        subtitle: "Language practice A1–C1",
                        systemImage: "graduationcap"
                    )

                    AgentTile(
                        title: "DreamMaker",
                        subtitle: "Generate & preview media",
                        systemImage: "sparkles"
                    )

                    AgentTile(
                        title: "Wallet",
                        subtitle: "WebCoin balance & history",
                        systemImage: "wallet.pass"
                    )

                }
                .padding()
            }
            .navigationTitle("WebKurier")
        }
    }
}