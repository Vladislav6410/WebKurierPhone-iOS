import Foundation
import CryptoKit

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
        // Replay reuses asset URLs, so validate again immediately before starting.
        // Residual TOCTOU: the SDK opens this path later; concurrent replacement is possible.
        try await SharedEngineIntegrity.validateCached(assets.sharedEngineURL)
        try Task.checkCancellation()
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

struct SharedEngineIntegrity: Sendable {
    let size: Int64
    let sha256: String

    static let production = SharedEngineIntegrity(
        size: AvatarAudioContract.sharedEngineSize,
        sha256: AvatarAudioContract.sharedEngineSHA256
    )

    static func validate(_ url: URL, expected: Self = .production) async throws {
        // Explicitly keep streaming IO/hash work off the caller's actor.
        let worker = Task.detached(priority: .utility) {
            try Task.checkCancellation()
            do {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values.isRegularFile == true, let size = values.fileSize,
                      Int64(size) == expected.size else {
                    throw AvatarPoCError.missingEngine("integrity check failed: unexpected file size or type")
                }
                let handle = try FileHandle(forReadingFrom: url)
                defer { try? handle.close() }
                var hash = SHA256()
                var count: Int64 = 0
                while true {
                    try Task.checkCancellation()
                    guard let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty else { break }
                    count += Int64(chunk.count)
                    guard count <= expected.size else {
                        throw AvatarPoCError.missingEngine("integrity check failed: file grew while reading")
                    }
                    hash.update(data: chunk)
                }
                let digest = hash.finalize().map { String(format: "%02x", $0) }.joined()
                guard count == expected.size, digest == expected.sha256 else {
                    throw AvatarPoCError.missingEngine("integrity check failed: size or SHA-256 mismatch")
                }
                try Task.checkCancellation()
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as AvatarPoCError {
                throw error
            } catch {
                throw AvatarPoCError.missingEngine("integrity check could not read file: \(error.localizedDescription)")
            }
        }
        try await withTaskCancellationHandler {
            try await worker.value
            try Task.checkCancellation()
        } onCancel: {
            worker.cancel()
        }
    }

    static func validateCached(_ url: URL, expected: Self = .production) async throws {
        do {
            try await validate(url, expected: expected)
        } catch is CancellationError {
            // Cancellation does not prove corruption; keep an existing cache intact.
            throw CancellationError()
        } catch {
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            } catch {
                throw AvatarPoCError.missingEngine("invalid cache could not be removed: \(error.localizedDescription)")
            }
            throw error
        }
    }
}

struct AvatarAssetLoader: AvatarAssetLoading {
    // Internal seams for isolated fixtures; the production defaults remain pinned.
    var root: URL? = nil
    var engineIntegrity: SharedEngineIntegrity = .production
    var fetch: (URL) async throws -> (URL, URLResponse) = { url in
        try await URLSession.shared.download(from: url)
    }

    func loadDemoAssets() async throws -> AvatarAssetSet {
        let root = try self.root ?? FileManager.default.url(
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
        try await download(AvatarAudioContract.sharedEngineDownloadURL, to: engine, integrity: engineIntegrity, missing: { .missingEngine($0) })
        try await download(AvatarAudioContract.speechDownloadURL, to: speech, missing: { .missingSpeech($0) })
        return AvatarAssetSet(avatarURL: avatar, sharedEngineURL: engine, speechURL: speech, stagingURL: staging)
    }

    private func download(_ remote: URL, to destination: URL, integrity: SharedEngineIntegrity? = nil,
                          missing: (String) -> AvatarPoCError) async throws {
        try Task.checkCancellation()
        if FileManager.default.fileExists(atPath: destination.path) {
            if let integrity {
                try await SharedEngineIntegrity.validateCached(destination, expected: integrity)
                return
            }
            if (try? destination.resourceValues(forKeys: [.fileSizeKey]).fileSize).map({ $0 > 0 }) == true {
                return
            }
        }
        do {
            let (temporary, response) = try await fetch(remote)
            // URLSession owns partial files on transport failure; once returned, we own cleanup.
            defer { try? FileManager.default.removeItem(at: temporary) }
            try Task.checkCancellation()
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                throw missing("HTTP \(http.statusCode)")
            }
            if let integrity {
                try await SharedEngineIntegrity.validate(temporary, expected: integrity)
            }
            try Task.checkCancellation()
            if FileManager.default.fileExists(atPath: destination.path) {
                if integrity != nil {
                    throw missing("cache destination appeared during download; retry")
                }
                try FileManager.default.removeItem(at: destination)
            }
            // Publish only a verified download. Residual TOCTOU: the SDK opens the path
            // after validation; concurrent filesystem replacement cannot be excluded here.
            try FileManager.default.moveItem(at: temporary, to: destination)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
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
