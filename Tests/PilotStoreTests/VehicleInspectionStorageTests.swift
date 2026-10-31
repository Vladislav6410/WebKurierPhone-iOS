import XCTest
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import WebKurierPilot

final class VehicleInspectionStorageTests: XCTestCase {
    // A real decodable JPEG with EXIF orientation and capture metadata, not a marker stub.
    private func jpegFixture() throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 8, height: 6)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 8, height: 6))
        }
        let data = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try XCTUnwrap(image.cgImage), [
            kCGImagePropertyOrientation: 6,
            kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: "2026:10:31 12:00:00"]
        ] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return data as Data
    }

    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    func testSaveAndReloadPreservesImageBytesAndMetadata() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let bytes = try jpegFixture()
        let saved = try VehicleInspectionStorage.save(imageData: bytes, panel: "Дверь", defect: "Царапина", note: "Слева", root: root)
        let loaded = try XCTUnwrap(VehicleInspectionStorage.load(root: root).first)
        XCTAssertEqual(loaded.id, saved.id)
        XCTAssertEqual(loaded.imageFormat, "public.jpeg")
        XCTAssertEqual(loaded.imageFilename, loaded.id.uuidString + ".jpg")
        let restored = try VehicleInspectionStorage.imageData(for: loaded, root: root)
        XCTAssertEqual(restored, bytes)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(restored as CFData, nil))
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any])
        XCTAssertEqual(properties[kCGImagePropertyOrientation as String] as? Int, 6)
        let exif = try XCTUnwrap(properties[kCGImagePropertyExifDictionary as String] as? [String: Any])
        XCTAssertEqual(exif[kCGImagePropertyExifDateTimeOriginal as String] as? String, "2026:10:31 12:00:00")
        XCTAssertEqual(try XCTUnwrap(UIImage(data: restored)).imageOrientation, .right)
        XCTAssertEqual(loaded.panel, "Дверь")
        XCTAssertEqual(loaded.defect, "Царапина")
        XCTAssertEqual(loaded.note, "Слева")
        XCTAssertEqual(try Data(contentsOf: VehicleInspectionStorage.directory(root: root).appendingPathComponent(loaded.imageFilename)), bytes)
    }

    func testEmptyImageRejectedWithoutCreatingRecord() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertThrowsError(try VehicleInspectionStorage.save(imageData: Data(), panel: "Капот", defect: "Скол", note: "", root: root))
        XCTAssertTrue(try VehicleInspectionStorage.load(root: root).isEmpty)
    }

    func testMissingDirectoryLoadsEmpty() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        XCTAssertTrue(try VehicleInspectionStorage.load(root: root).isEmpty)
    }
    func testUnsupportedAndCorruptEncodingsRejected() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let png = try XCTUnwrap(UIImage(data: jpegFixture())?.pngData())
        for bytes in [png, Data("not an image".utf8), Data([0xFF, 0xD8, 0xFF, 0xD9]), Data(try jpegFixture().dropLast(20))] {
            XCTAssertThrowsError(try VehicleInspectionStorage.save(imageData: bytes, panel: "", defect: "", note: "", root: root))
        }
        XCTAssertTrue(try VehicleInspectionStorage.load(root: root).isEmpty)
    }

    func testMissingCorruptAndMismatchedSavedImageRejected() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let record = try VehicleInspectionStorage.save(imageData: jpegFixture(), panel: "", defect: "", note: "", root: root)
        let url = VehicleInspectionStorage.directory(root: root).appendingPathComponent(record.imageFilename)
        try Data("corrupt".utf8).write(to: url)
        XCTAssertThrowsError(try VehicleInspectionStorage.imageData(for: record, root: root))
        try FileManager.default.removeItem(at: url)
        XCTAssertThrowsError(try VehicleInspectionStorage.imageData(for: record, root: root))
        let mismatched = VehicleInspection(id: record.id, createdAt: record.createdAt, panel: "", defect: "", note: "", imageFilename: record.id.uuidString + ".heic", imageFormat: "public.jpeg")
        XCTAssertThrowsError(try VehicleInspectionStorage.imageData(for: mismatched, root: root))
    }

    func testWriteFailureAndMalformedRecordAreReported() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = VehicleInspectionStorage.directory(root: root)
        try Data("blocks directory".utf8).write(to: folder)
        XCTAssertThrowsError(try VehicleInspectionStorage.save(imageData: jpegFixture(), panel: "", defect: "", note: "", root: root))
        try FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try Data("invalid JSON".utf8).write(to: folder.appendingPathComponent("broken.json"))
        XCTAssertThrowsError(try VehicleInspectionStorage.load(root: root))
    }

}
