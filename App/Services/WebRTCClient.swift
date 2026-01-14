import Foundation
import AVFoundation

final class WebRTCClient {

    static let shared = WebRTCClient()
    private init() {}

    private(set) var isConnected: Bool = false

    func startCall() {
        // Placeholder: real WebRTC signaling via PhoneCore
        configureAudioSession()
        isConnected = true
        print("WebRTC call started")
    }

    func endCall() {
        isConnected = false
        deactivateAudioSession()
        print("WebRTC call ended")
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
        try? session.setActive(true)
    }

    private func deactivateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false)
    }
}