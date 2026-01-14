import Foundation
import AVFoundation

final class AudioEngine {

    static let shared = AudioEngine()
    private init() {}

    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let outputNode: AVAudioOutputNode

    private(set) var isRunning: Bool = false

    init(engine: AVAudioEngine = AVAudioEngine()) {
        self.audioEngine = engine
        self.inputNode = engine.inputNode
        self.outputNode = engine.outputNode
    }

    func start() {
        guard !isRunning else { return }

        configureSession()
        do {
            try audioEngine.start()
            isRunning = true
            print("AudioEngine started")
        } catch {
            print("AudioEngine start failed:", error)
        }
    }

    func stop() {
        guard isRunning else { return }

        audioEngine.stop()
        isRunning = false
        deactivateSession()
        print("AudioEngine stopped")
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)
    }

    private func deactivateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(false)
    }
}