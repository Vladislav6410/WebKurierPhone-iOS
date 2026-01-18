import SwiftUI

struct WalletView: View {

    @EnvironmentObject private var coreGateway: CoreGateway

    @State private var balance: Int = 0
    @State private var isLoading: Bool = true
    @State private var statusText: String = "Loading…"

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {

                if isLoading {
                    ProgressView()
                }

                Text("WebCoin Balance")
                    .font(.headline)

                Text("\(balance)")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)

                Button {
                    loadBalance()
                } label: {
                    Text("Refresh")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)

                Spacer()
            }
            .padding()
            .navigationTitle("Wallet")
            .onAppear(perform: loadBalance)
        }
    }

    private func loadBalance() {
        guard !isLoading else { return }
        isLoading = true
        statusText = "Loading…"

        // Placeholder: replace with Core wallet endpoint when available
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            balance = 0
            statusText = "Updated"
            isLoading = false
        }
    }
}