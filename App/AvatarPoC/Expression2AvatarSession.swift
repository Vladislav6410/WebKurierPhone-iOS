import AVFoundation
import Foundation
import os
#if canImport(Expression2)
import Expression2
#endif

/// Expression2 lives only in this file.
final class Expression2AvatarSession: Expression2Sessioning {
    private var playback: Playback?
    private var renderTask: Task<Void, Never>?
    #if canImport(Expression2)
    private var engine: Expression2Engine?
    #endif

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
        self.engine = engine
        let playback = Playback(samples: samples)
        self.playback = playback
        try playback.activatePlaybackSession()
        try playback.startEngine()
        engine.feed(samples)
        engine.flushTail()
        let clock = PlaybackClock(playback)
        renderTask = Task {
            defer { engine.shutdown() }
            for await frame in engine.frames(audioClock: { clock.playedSeconds() }) {
                if Task.isCancelled { break }
                if AvatarSpeechStartPolicy.shouldStartReply(audioTime: frame.audioTime, alreadyStarted: playback.replyStarted) {
                    playback.playReply()
                }
                let rendered = AvatarFrame(
                    bgr: Array(frame.bgr),
                    width: frame.width,
                    height: frame.height,
                    audioTime: frame.audioTime ?? -1,
                    endsReply: frame.endsReply
                )
                await MainActor.run { onFrame(rendered) }
                if frame.endsReply { break }
            }
        }
        #else
        _ = secret
        throw AvatarPoCError.engineInitializationFailed("Expression2 is not linked in this build")
        #endif
    }

    func stop() {
        renderTask?.cancel()
        renderTask = nil
        #if canImport(Expression2)
        engine?.shutdown()
        engine = nil
        #endif
        playback?.stop()
        playback = nil
    }
}

private final class PlaybackClock: @unchecked Sendable {
    private let playback: Playback
    init(_ playback: Playback) { self.playback = playback }
    func playedSeconds() -> Double? { playback.playedSeconds() }
}

private final class Playback: @unchecked Sendable {
    let samples: [Float]
    let engine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 16_000, channels: 1)!
    private let started = OSAllocatedUnfairLock(initialState: false)

    init(samples: [Float]) {
        self.samples = samples
    }

    var replyStarted: Bool { started.withLock { $0 } }

    func activatePlaybackSession() throws {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            throw AvatarPoCError.playbackFailed(error.localizedDescription)
        }
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
        let shouldSchedule = started.withLock { value -> Bool in
            if value { return false }
            value = true
            return true
        }
        guard shouldSchedule else { return }
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count)) else { return }
        buffer.frameLength = buffer.frameCapacity
        samples.withUnsafeBufferPointer { source in
            guard let address = source.baseAddress else { return }
            buffer.floatChannelData?[0].update(from: address, count: samples.count)
        }
        player.scheduleBuffer(buffer, completionHandler: nil)
        player.play()
    }

    func playedSeconds() -> Double? {
        guard replyStarted, let nodeTime = player.lastRenderTime, let playerTime = player.playerTime(forNodeTime: nodeTime) else {
            return nil
        }
        return Double(playerTime.sampleTime) / playerTime.sampleRate
    }

    func stop() {
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
