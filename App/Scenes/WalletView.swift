import SwiftUI

struct WalletView: View {

    @State private var balance: Int = 0
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                if isLoading {
                    ProgressView()
                } else {
                    Text("WebCoin Balance")
                        .font(.headline)

                    Text("\(balance)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Wallet")
            .onAppear(perform: loadBalance)
        }
    }

    private func loadBalance() {
        // Placeholder: balance fetched via Core → Chain
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            balance = 0
            isLoading = false
        }
    }
}