import Foundation

final class FileProcessor {

    static let shared = FileProcessor()
    private init() {}

    func readText(from url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }

    func fileSize(of url: URL) -> Int64 {
        (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }

    func copyToTemporaryDirectory(_ url: URL) -> URL? {
        let tempDir = FileManager.default.temporaryDirectory
        let destination = tempDir.appendingPathComponent(url.lastPathComponent)

        try? FileManager.default.removeItem(at: destination)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
            return destination
        } catch {
            return nil
        }
    }
}