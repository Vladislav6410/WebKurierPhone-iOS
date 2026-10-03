import AVFoundation
import Foundation
#if canImport(Expression2)
import Expression2
#endif

/// Expression2 lives only in this file.
final class Expression2AvatarSession: Expression2Sessioning {
    private var playback: Playback?
    private var renderTask: Task<Void, Never>?

    func start(assets: AvatarAssetSet, samples: [Float], onFrame: @escaping (AvatarFrame) -> Void) async throws {
        stop()
        guard FileManager.default.fileExists(atPath: assets.avatarURL.path) else {
            throw AvatarPoCError.missingAvatar("file missing at \(assets.avatarURL.lastPathComponent)")
        }
        guard FileManager.default.fileExists(atPath: assets.sharedEngineURL.path) else {
            throw AvatarPoCError.missingEngine("file missing at \(assets.sharedEngineURL.lastPathComponent)")
        }
        guard let secret = AvatarSecretSource.developmentSecret() else {
            throw AvatarPoCError.missingSecret
        }
        #if canImport(Expression2)
        Expression2Credential.set(secret)
        let engine: Expression2Engine
        do {
            engine = try Expression2Engine.create(
                avatarContainer: assets.avatarURL,
                sharedEngineContainer: assets.sharedEngineURL,
                stagingDir: assets.stagingURL
            )
        } catch {
            throw AvatarPoCError.engineInitializationFailed(error.localizedDescription)
        }
        let playback = Playback(samples: samples)
        self.playback = playback
        try playback.startEngine()
        engine.feed(samples)
        engine.flushTail()
        let clock = playback.playedSeconds
        renderTask = Task {
            for await frame in engine.frames(audioClock: { clock() }) {
                if Task.isCancelled { break }
                let rendered = AvatarFrame(
                    bgr: Array(frame.bgr),
                    width: frame.width,
                    height: frame.height,
                    audioTime: frame.audioTime,
                    endsReply: frame.endsReply
                )
                await MainActor.run {
                    onFrame(rendered)
                    if rendered.audioTime == 0 {
                        playback.playReply()
                    }
                }
                if frame.endsReply { break }
            }
            engine.shutdown()
        }
        #else
        _ = secret
        throw AvatarPoCError.engineInitializationFailed("Expression2 is not linked in this build")
        #endif
    }

    func stop() {
        renderTask?.cancel()
        renderTask = nil
        playback?.stop()
        playback = nil
    }
}

private final class Playback {
    let samples: [Float]
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!

    init(samples: [Float]) {
        self.samples = samples
    }

    func startEngine() throws {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try engine.start()
        } catch {
            throw AvatarPoCError.playbackFailed(error.localizedDescription)
        }
    }

    func playReply() {
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { source in
            guard let address = source.baseAddress else { return }
            buffer.floatChannelData?[0].update(from: address, count: samples.count)
        }
        player.stop()
        player.scheduleBuffer(buffer, completionHandler: nil)
        player.play()
    }

    func playedSeconds() -> Double? {
        guard let nodeTime = player.lastRenderTime, let playerTime = player.playerTime(forNodeTime: nodeTime) else {
            return nil
        }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    func stop() {
        player.stop()
        engine.stop()
    }
}
