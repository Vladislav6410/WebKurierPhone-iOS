import SwiftUI

struct CafeView: View {

    @State private var orderStatus: String = "No active order"

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {

                Text(orderStatus)
                    .font(.headline)

                Button(action: placeOrder) {
                    Text("Order Coffee")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Cafe")
        }
    }

    private func placeOrder() {
        // Placeholder: CafeAgent via Core
        orderStatus = "Order sent"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            orderStatus = "Preparing…"
        }
    }
}