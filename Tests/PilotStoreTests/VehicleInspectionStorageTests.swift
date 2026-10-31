import XCTest
@testable import WebKurierPilot

final class VehicleInspectionStorageTests: XCTestCase {
    private func temporaryRoot() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        return root
    }

    func testSaveAndReloadPreservesImageBytesAndMetadata() throws {
        let root = try temporaryRoot()
        defer { try? FileManager.default.removeItem(at: root) }
        let bytes = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let saved = try VehicleInspectionStorage.save(imageData: bytes, panel: "Дверь", defect: "Царапина", note: "Слева", root: root)
        let loaded = try XCTUnwrap(VehicleInspectionStorage.load(root: root).first)
        XCTAssertEqual(loaded.id, saved.id)
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
}
