import Foundation

struct VoiceCallModel: Identifiable {
    let id = UUID()

    let peerId: String
    let startedAt: Date
    let isActive: Bool
}