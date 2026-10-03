import Foundation

/// Boundary between WebKurier UI and Expression2. Callers never see the SDK.
protocol BitHumanAvatarAdapting: AnyObject {
    func loadPermittedDemoAssets() async throws -> AvatarAssetSet
    func loadPreparedSpeech(from url: URL) async throws -> [Float]
    func start(assets: AvatarAssetSet, samples: [Float], onFrame: @escaping (AvatarFrame) -> Void) async throws
    func stop()
}

final class BitHumanAvatarAdapter: BitHumanAvatarAdapting {
    private let session: Expression2Sessioning
    private let loader: AvatarAssetLoading

    init(session: Expression2Sessioning = Expression2AvatarSession(), loader: AvatarAssetLoading = AvatarAssetLoader()) {
        self.session = session
        self.loader = loader
    }

    func loadPermittedDemoAssets() async throws -> AvatarAssetSet {
        try await loader.loadDemoAssets()
    }

    func loadPreparedSpeech(from url: URL) async throws -> [Float] {
        let samples = try AvatarSpeechDecoder.samples(fromWAV: url)
        if let error = AvatarAudioContract.validate(samples: samples, sampleRate: AvatarAudioContract.sampleRate, channels: 1) {
            throw error
        }
        return samples
    }

    func start(assets: AvatarAssetSet, samples: [Float], onFrame: @escaping (AvatarFrame) -> Void) async throws {
        if let error = AvatarAudioContract.validate(samples: samples, sampleRate: AvatarAudioContract.sampleRate, channels: 1) {
            throw error
        }
        guard AvatarSecretSource.developmentSecret() != nil else { throw AvatarPoCError.missingSecret }
        do {
            try await session.start(assets: assets, samples: samples, onFrame: onFrame)
        } catch let error as AvatarPoCError {
            throw error
        } catch {
            throw AvatarPoCError.engineInitializationFailed(error.localizedDescription)
        }
    }

    func stop() {
        session.stop()
    }
}

protocol Expression2Sessioning: AnyObject {
    func start(assets: AvatarAssetSet, samples: [Float], onFrame: @escaping (AvatarFrame) -> Void) async throws
    func stop()
}

protocol AvatarAssetLoading {
    func loadDemoAssets() async throws -> AvatarAssetSet
}

struct AvatarAssetLoader: AvatarAssetLoading {
    func loadDemoAssets() async throws -> AvatarAssetSet {
        let root = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appendingPathComponent("AvatarPoC", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let avatar = root.appendingPathComponent("A23WJF0199.imx")
        let engine = root.appendingPathComponent("mac-arm64-1.0.0.engine")
        let speech = root.appendingPathComponent("speech16k.wav")
        let staging = root.appendingPathComponent("staging", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        try await download(AvatarAudioContract.avatarDownloadURL, to: avatar, missing: { .missingAvatar($0) })
        try await download(AvatarAudioContract.sharedEngineDownloadURL, to: engine, missing: { .missingEngine($0) })
        try await download(AvatarAudioContract.speechDownloadURL, to: speech, missing: { .missingSpeech($0) })
        return AvatarAssetSet(avatarURL: avatar, sharedEngineURL: engine, speechURL: speech, stagingURL: staging)
    }

    private func download(_ remote: URL, to destination: URL, missing: (String) -> AvatarPoCError) async throws {
        if FileManager.default.fileExists(atPath: destination.path),
           (try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize).map({ $0 > 0 }) == true {
            return
        }
        do {
            let (temporary, response) = try await URLSession.shared.download(from: remote)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw missing("HTTP \(http.statusCode)")
            }
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.moveItem(at: temporary, to: destination)
        } catch let error as AvatarPoCError {
            throw error
        } catch {
            throw missing(error.localizedDescription)
        }
    }
}

enum AvatarSpeechDecoder {
    static func samples(fromWAV url: URL) throws -> [Float] {
        let data = try Data(contentsOf: url)
        guard data.count > 44, String(data: data.prefix(4), encoding: .ascii) == "RIFF" else {
            throw AvatarPoCError.invalidAudio(reason: "prepared speech is not a WAV file")
        }
        let sampleRate = int32(data, 24)
        let channels = int16(data, 22)
        let bits = int16(data, 34)
        guard sampleRate == AvatarAudioContract.sampleRate, channels == 1, bits == 16 else {
            throw AvatarPoCError.invalidAudio(reason: "prepared speech must be 16 kHz mono 16-bit WAV")
        }
        let pcm = data.dropFirst(44)
        var samples: [Float] = []
        samples.reserveCapacity(pcm.count / 2)
        var index = pcm.startIndex
        while index + 1 < pcm.endIndex {
            let value = Int16(bitPattern: UInt16(pcm[index]) | (UInt16(pcm[index + 1]) << 8))
            samples.append(Float(value) / 32768)
            index += 2
        }
        if let error = AvatarAudioContract.validate(samples: samples, sampleRate: Int(sampleRate), channels: Int(channels)) {
            throw error
        }
        return samples
    }

    private static func int16(_ data: Data, _ offset: Int) -> Int {
        Int(UInt16(data[offset]) | (UInt16(data[offset + 1]) << 8))
    }

    private static func int32(_ data: Data, _ offset: Int) -> Int {
        Int(UInt32(data[offset]) | (UInt32(data[offset + 1]) << 8) | (UInt32(data[offset + 2]) << 16) | (UInt32(data[offset + 3]) << 24))
    }
}
