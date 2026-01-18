import SwiftUI

struct CafeView: View {

    @State private var orderStatus: String = "No active order"
    @State private var isSending: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {

                Text(orderStatus)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.orange.opacity(0.08))
                    .cornerRadius(8)

                Button {
                    placeOrder()
                } label: {
                    HStack(spacing: 10) {
                        if isSending { ProgressView() }
                        Text(isSending ? "Sending…" : "Order Coffee")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isSending)

                Spacer()
            }
            .padding()
            .navigationTitle("Cafe")
        }
    }

    private func placeOrder() {
        isSending = true

        // Placeholder: CafeAgent via Core
        orderStatus = "Order sent"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            orderStatus = "Preparing…"
            isSending = false
        }
    }
}