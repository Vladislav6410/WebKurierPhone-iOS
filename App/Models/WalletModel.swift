import Foundation

struct WalletModel: Identifiable {
    let id = UUID()

    let balance: Int
    let currency: String
    let updatedAt: Date
}