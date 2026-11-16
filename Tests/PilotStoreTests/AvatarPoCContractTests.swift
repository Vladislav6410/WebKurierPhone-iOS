import XCTest
@testable import WebKurierPilot

final class AvatarPoCContractTests: XCTestCase {
    func testAccepts16kMonoSpeech() {
        XCTAssertNil(AvatarAudioContract.validate(samples: [0, 0.25, -0.25], sampleRate: 16_000, channels: 1))
    }

    func testRejectsWrongRateAndEmptyAndNonFiniteAudio() {
        XCTAssertEqual(
            AvatarAudioContract.validate(samples: [0], sampleRate: 24_000, channels: 1),
            .invalidAudio(reason: "Expression2 requires 16000 Hz mono PCM, got 24000 Hz / 1 ch")
        )
        XCTAssertEqual(
            AvatarAudioContract.validate(samples: [], sampleRate: 16_000, channels: 1),
            .invalidAudio(reason: "audio buffer is empty")
        )
        XCTAssertEqual(
            AvatarAudioContract.validate(samples: [.nan], sampleRate: 16_000, channels: 1),
            .invalidAudio(reason: "audio contains non-finite samples")
        )
    }

    func testMissingSecretIsExplicit() {
        XCTAssertEqual(AvatarPoCError.missingSecret.message.contains("BITHUMAN_API_SECRET"), true)
        XCTAssertNil(AvatarSecretSource.developmentSecret())
    }

    func testDemoAssetIdentityIsTheDocumentedSample() {
        XCTAssertEqual(AvatarAudioContract.demoAgentCode, "A23WJF0199")
        XCTAssertEqual(AvatarAudioContract.frameWidth, 416)
        XCTAssertEqual(AvatarAudioContract.frameHeight, 720)
        XCTAssertFalse(AvatarAudioContract.avatarDownloadURL.absoluteString.contains("secret"))
    }

    func testSpeechStartsOnlyOnFirstZeroAudioTime() {
        XCTAssertFalse(AvatarSpeechStartPolicy.shouldStartReply(audioTime: nil, alreadyStarted: false))
        XCTAssertTrue(AvatarSpeechStartPolicy.shouldStartReply(audioTime: 0, alreadyStarted: false))
        XCTAssertFalse(AvatarSpeechStartPolicy.shouldStartReply(audioTime: 0, alreadyStarted: true))
        XCTAssertFalse(AvatarSpeechStartPolicy.shouldStartReply(audioTime: 0.05, alreadyStarted: false))
    }
}

final class SharedEngineIntegrityTests: XCTestCase {
    private let abc = Data("abc".utf8)
    private let expected = SharedEngineIntegrity(
        size: 3, sha256: "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    )

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    private func seedOtherAssets(_ root: URL) throws {
        try abc.write(to: root.appendingPathComponent("A23WJF0199.imx"))
        try abc.write(to: root.appendingPathComponent("speech16k.wav"))
    }

    private func response() -> URLResponse {
        HTTPURLResponse(url: AvatarAudioContract.sharedEngineDownloadURL,
                        statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    private func expectMissingEngine(_ operation: () async throws -> Void,
                                     file: StaticString = #filePath, line: UInt = #line) async {
        do {
            try await operation()
            XCTFail("Expected controlled engine error", file: file, line: line)
        } catch let error as AvatarPoCError {
            guard case .missingEngine = error else {
                XCTFail("Unexpected error: \(error)", file: file, line: line)
                return
            }
        } catch {
            XCTFail("Uncontrolled error: \(error)", file: file, line: line)
        }
    }

    func testProductionPinsMatchVendorManifest() {
        XCTAssertEqual(AvatarAudioContract.sharedEngineSize, 173_440_528)
        XCTAssertEqual(AvatarAudioContract.sharedEngineSHA256,
                       "58aa0615bc26f2cd7a6b9f2de15fa5585eef8bac801a8f38ae9d4bdcabd8f68a")
    }

    func testValidFileAndSameSizeWrongHash() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("engine")
        try abc.write(to: file)
        try await SharedEngineIntegrity.validate(file, expected: expected)
        try Data("abd".utf8).write(to: file)
        await expectMissingEngine { try await SharedEngineIntegrity.validate(file, expected: self.expected) }
    }

    func testStreamingValidationAcrossMultipleChunks() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("engine")
        try Data(repeating: 0x61, count: 2_097_169).write(to: file)
        try await SharedEngineIntegrity.validate(file, expected: SharedEngineIntegrity(
            size: 2_097_169, sha256: "c2273a45bd6d19d2714b8279b1fd1123bb746e7f7f6331085fb6ecaa30164546"
        ))
    }

    func testTruncatedAndMissingFileAreControlledErrors() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("engine")
        await expectMissingEngine { try await SharedEngineIntegrity.validate(file, expected: self.expected) }
        try Data("ab".utf8).write(to: file)
        await expectMissingEngine { try await SharedEngineIntegrity.validate(file, expected: self.expected) }
    }

    func testCorruptCacheIsRemovedWithoutDownloadOrReuse() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try seedOtherAssets(root)
        let file = root.appendingPathComponent("mac-arm64-1.0.0.engine")
        try Data("abd".utf8).write(to: file)
        let loader = AvatarAssetLoader(root: root, engineIntegrity: expected, fetch: { _ in
            XCTFail("Corrupt cache must fail this attempt, not silently retry")
            throw URLError(.badServerResponse)
        })
        await expectMissingEngine { _ = try await loader.loadDemoAssets() }
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
    }

    func testValidatedDownloadIsPublishedAndReused() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try seedOtherAssets(root)
        let temporary = root.appendingPathComponent("download.tmp")
        try abc.write(to: temporary)
        let response = response()
        let loader = AvatarAssetLoader(root: root, engineIntegrity: expected, fetch: { _ in
            return (temporary, response)
        })
        let assets = try await loader.loadDemoAssets()
        XCTAssertEqual(try Data(contentsOf: assets.sharedEngineURL), abc)
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporary.path))
        let cached = AvatarAssetLoader(root: root, engineIntegrity: expected, fetch: { _ in
            XCTFail("Valid cache must not download")
            throw URLError(.badServerResponse)
        })
        _ = try await cached.loadDemoAssets()
    }

    func testPartialAndWrongHashDownloadsNeverBecomeCache() async throws {
        for payload in [Data("a".utf8), Data("abd".utf8)] {
            let root = try temporaryRoot()
            defer { try? FileManager.default.removeItem(at: root) }
            try seedOtherAssets(root)
            let temporary = root.appendingPathComponent("download.tmp")
            try payload.write(to: temporary)
            let response = response()
            let loader = AvatarAssetLoader(root: root, engineIntegrity: expected, fetch: { _ in
                (temporary, response)
            })
            await expectMissingEngine { _ = try await loader.loadDemoAssets() }
            XCTAssertFalse(FileManager.default.fileExists(atPath: temporary.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("mac-arm64-1.0.0.engine").path))
        }
    }

    func testInterruptedTransportDoesNotPublishCache() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try seedOtherAssets(root)
        let loader = AvatarAssetLoader(root: root, engineIntegrity: expected, fetch: { _ in
            throw URLError(.networkConnectionLost)
        })
        await expectMissingEngine { _ = try await loader.loadDemoAssets() }
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("mac-arm64-1.0.0.engine").path))
    }

    func testCancellationAfterDownloadCleansTemporaryWithoutPublishing() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        try seedOtherAssets(root)
        let temporary = root.appendingPathComponent("download.tmp")
        try abc.write(to: temporary)
        let response = response()
        let loader = AvatarAssetLoader(root: root, engineIntegrity: expected, fetch: { _ in
            withUnsafeCurrentTask { $0?.cancel() }
            return (temporary, response)
        })
        let task = Task { try await loader.loadDemoAssets() }
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: temporary.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: root.appendingPathComponent("mac-arm64-1.0.0.engine").path))
    }

    func testCancelledValidationPreservesExistingCache() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("engine")
        try abc.write(to: file)
        let expected = expected
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            try await SharedEngineIntegrity.validateCached(file, expected: expected)
        }
        do {
            try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
        XCTAssertEqual(try Data(contentsOf: file), abc)
    }

    func testStartAndReplayRejectCorruptEngineBeforeSessionOrSecret() async throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let file = root.appendingPathComponent("engine")
        let session = IntegritySessionSpy()
        let adapter = BitHumanAvatarAdapter(session: session)
        let assets = AvatarAssetSet(avatarURL: file, sharedEngineURL: file, speechURL: file, stagingURL: root)
        for _ in 0..<2 {
            try abc.write(to: file)
            await expectMissingEngine {
                try await adapter.start(assets: assets, samples: [0], onFrame: { _ in })
            }
            XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        }
        XCTAssertEqual(session.starts, 0)
    }
}

private final class IntegritySessionSpy: Expression2Sessioning {
    var starts = 0
    func start(assets: AvatarAssetSet, samples: [Float], onFrame: @escaping (AvatarFrame) -> Void) async throws {
        starts += 1
    }
    func stop() {}
}
