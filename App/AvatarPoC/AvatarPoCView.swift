import SwiftUI

struct AvatarPoCView: View {
    @StateObject private var model = AvatarPoCModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                frameView
                    .frame(maxWidth: 280)
                    .aspectRatio(CGFloat(AvatarAudioContract.frameWidth) / CGFloat(AvatarAudioContract.frameHeight), contentMode: .fit)
                Text(model.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                HStack {
                    Button(model.isRunning ? "Stop" : "Play") {
                        if model.isRunning {
                            model.stop()
                        } else {
                            model.play()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Button("Replay") { model.replay() }
                        .buttonStyle(.bordered)
                        .disabled(model.isRunning)
                }
                Text("Demo avatar \(AvatarAudioContract.demoAvatarName) (\(AvatarAudioContract.demoAgentCode)). Secret stays in the scheme environment.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()
            .navigationTitle("Avatar PoC")
        }
    }

    @ViewBuilder
    private var frameView: some View {
        if let image = model.image {
            image.resizable().scaledToFit()
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.secondary.opacity(0.15))
                .overlay { Text("No frame yet").foregroundStyle(.secondary) }
        }
    }
}

@MainActor
final class AvatarPoCModel: ObservableObject {
    @Published var status = "Idle"
    @Published var image: Image?
    @Published var isRunning = false

    private let adapter: BitHumanAvatarAdapting
    private var assets: AvatarAssetSet?
    private var samples: [Float]?

    init(adapter: BitHumanAvatarAdapting = BitHumanAvatarAdapter()) {
        self.adapter = adapter
    }

    func play() {
        isRunning = true
        status = "Loading permitted demo avatar"
        Task {
            do {
                let assets = try await adapter.loadPermittedDemoAssets()
                self.assets = assets
                status = "Loading prepared test speech"
                let samples = try await adapter.loadPreparedSpeech(from: assets.speechURL)
                self.samples = samples
                try await run(assets: assets, samples: samples)
            } catch let error as AvatarPoCError {
                fail(error.message)
            } catch {
                fail(error.localizedDescription)
            }
        }
    }

    func replay() {
        guard let assets, let samples else {
            play()
            return
        }
        isRunning = true
        Task {
            do { try await run(assets: assets, samples: samples) }
            catch let error as AvatarPoCError { fail(error.message) }
            catch { fail(error.localizedDescription) }
        }
    }

    func stop() {
        adapter.stop()
        isRunning = false
        status = "Stopped"
    }

    private func run(assets: AvatarAssetSet, samples: [Float]) async throws {
        status = "Rendering lip-synced frames"
        try await adapter.start(assets: assets, samples: samples) { [weak self] frame in
            self?.image = AvatarFrameImage.make(frame)
            if frame.endsReply {
                self?.isRunning = false
                self?.status = "Reply finished"
            }
        }
    }

    private func fail(_ message: String) {
        isRunning = false
        status = message
    }
}

enum AvatarFrameImage {
    static func make(_ frame: AvatarFrame) -> Image? {
        guard frame.width > 0, frame.height > 0, frame.bgr.count >= frame.width * frame.height * 3 else { return nil }
        var rgba = [UInt8](repeating: 255, count: frame.width * frame.height * 4)
        for pixel in 0..<(frame.width * frame.height) {
            rgba[pixel * 4] = frame.bgr[pixel * 3 + 2]
            rgba[pixel * 4 + 1] = frame.bgr[pixel * 3 + 1]
            rgba[pixel * 4 + 2] = frame.bgr[pixel * 3]
        }
        let data = Data(rgba)
        guard let provider = CGDataProvider(data: data as CFData),
              let cg = CGImage(
                width: frame.width,
                height: frame.height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: frame.width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else { return nil }
        return Image(decorative: cg, scale: 1)
    }
}
