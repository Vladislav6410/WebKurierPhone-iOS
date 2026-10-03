import XCTest

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
}
