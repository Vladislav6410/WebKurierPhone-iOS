import SwiftUI
import UIKit
import ImageIO
import UniformTypeIdentifiers

struct VehicleInspection: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let panel: String
    let defect: String
    let note: String
    let imageFilename: String
    // Optional for records created before format validation was introduced.
    let imageFormat: String?
}

enum VehicleInspectionStorage {
    /// Only JPEG is accepted. Decode for validation/preview, never for rewriting the source.
    static func validateJPEG(_ data: Data) throws {
        guard data.starts(with: [0xFF, 0xD8, 0xFF]),
              data.suffix(2) == Data([0xFF, 0xD9]),
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              (CGImageSourceGetType(source) as String?) == UTType.jpeg.identifier,
              CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceCreateImageAtIndex(source, 0, nil) != nil else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    static func imageData(for record: VehicleInspection, root: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) throws -> Data {
        guard record.imageFilename == record.id.uuidString + ".jpg",
              record.imageFormat == nil || record.imageFormat == "public.jpeg" else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let bytes = try Data(contentsOf: directory(root: root).appendingPathComponent(record.imageFilename))
        try validateJPEG(bytes)
        return bytes
    }

    static func directory(root: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) -> URL {
        root.appendingPathComponent("VehicleInspect", isDirectory: true)
    }

    static func save(imageData: Data, panel: String, defect: String, note: String, root: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) throws -> VehicleInspection {
        try validateJPEG(imageData)
        let folder = directory(root: root)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let id = UUID()
        let filename = id.uuidString + ".jpg"
        let imageURL = folder.appendingPathComponent(filename)
        let recordURL = folder.appendingPathComponent(id.uuidString + ".json")
        let record = VehicleInspection(id: id, createdAt: Date(), panel: panel, defect: defect, note: note, imageFilename: filename, imageFormat: "public.jpeg")
        do {
            try imageData.write(to: imageURL, options: .atomic)
            try JSONEncoder().encode(record).write(to: recordURL, options: .atomic)
        } catch {
            try? FileManager.default.removeItem(at: imageURL)
            throw error
        }
        return record
    }

    static func load(root: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) throws -> [VehicleInspection] {
        let folder = directory(root: root)
        guard FileManager.default.fileExists(atPath: folder.path) else { return [] }
        return try FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .map { try JSONDecoder().decode(VehicleInspection.self, from: Data(contentsOf: $0)) }
            .sorted { $0.createdAt > $1.createdAt }
    }
}

struct VehicleInspectView: View {
    @State private var showingCamera = false
    @State private var photoData: Data?
    @State private var panel = "Дверь"
    @State private var defect = "Царапина"
    @State private var note = ""
    @State private var records: [VehicleInspection] = []
    @State private var selected: VehicleInspection?
    @State private var errorMessage: String?
    @State private var cameraError: String?

    var body: some View {
        Form {
            Section("Новая инспекция") {
                Picker("Панель", selection: $panel) {
                    ForEach(["Дверь", "Капот", "Крыло", "Крыша", "Бампер", "Крышка багажника", "Другая"], id: \.self) { Text($0) }
                }
                Picker("Видимый дефект", selection: $defect) {
                    ForEach(["Царапина", "Вмятина", "Скол", "Потёртость", "Другое"], id: \.self) { Text($0) }
                }
                TextField("Комментарий", text: $note)
                Button("Сфотографировать панель") {
                    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
                        errorMessage = "Камера недоступна на этом устройстве."
                        return
                    }
                    showingCamera = true
                }
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 240)
                    Button("Сохранить оригинал и запись") { save(photoData) }
                }
            }
            Section("Сохранённые инспекции") {
                ForEach(records) { record in
                    Button {
                        selected = record
                    } label: {
                        VStack(alignment: .leading) {
                            Text(record.panel + " — " + record.defect)
                            Text(record.createdAt.formatted()).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Text("Только визуальная фиксация. Толщина краски и скрытые повреждения не измеряются.")
                .font(.footnote)
        }
        .navigationTitle("VehicleInspect")
        .onAppear(perform: reload)
        .sheet(isPresented: $showingCamera, onDismiss: {
            errorMessage = cameraError
            cameraError = nil
        }) {
            VehicleCameraView(onPhoto: { bytes in
                do {
                    try VehicleInspectionStorage.validateJPEG(bytes)
                    photoData = bytes
                } catch {
                    cameraError = "Камера вернула неподдерживаемый или повреждённый JPEG. Повторите съёмку."
                }
                showingCamera = false
            }, onCancel: {
                showingCamera = false
            }, onError: { message in
                cameraError = message
                showingCamera = false
            })
        }
        .sheet(item: $selected) { record in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let data = try? VehicleInspectionStorage.imageData(for: record),
                       let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        Text("Не удалось открыть исходное изображение.")
                    }
                    Text(record.panel + " — " + record.defect).font(.headline)
                    Text(record.note)
                    Text(record.createdAt.formatted())
                }.padding()
            }
        }
        .alert("VehicleInspect", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }

    private func save(_ data: Data) {
        do {
            _ = try VehicleInspectionStorage.save(imageData: data, panel: panel, defect: defect, note: note)
            photoData = nil
            note = ""
            reload()
        } catch {
            errorMessage = "Ошибка сохранения: " + error.localizedDescription
        }
    }

    private func reload() {
        do { records = try VehicleInspectionStorage.load() }
        catch { errorMessage = "Ошибка чтения инспекций: " + error.localizedDescription }
    }
}
