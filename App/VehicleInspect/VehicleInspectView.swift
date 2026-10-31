import SwiftUI
import UIKit

struct VehicleInspection: Codable, Identifiable {
    let id: UUID
    let createdAt: Date
    let panel: String
    let defect: String
    let note: String
    let imageFilename: String
}

enum VehicleInspectionStorage {
    static func directory(root: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) -> URL {
        root.appendingPathComponent("VehicleInspect", isDirectory: true)
    }

    static func save(imageData: Data, panel: String, defect: String, note: String, root: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]) throws -> VehicleInspection {
        guard !imageData.isEmpty else { throw CocoaError(.fileReadCorruptFile) }
        let folder = directory(root: root)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let id = UUID()
        let filename = id.uuidString + ".jpg"
        let imageURL = folder.appendingPathComponent(filename)
        let recordURL = folder.appendingPathComponent(id.uuidString + ".json")
        let record = VehicleInspection(id: id, createdAt: Date(), panel: panel, defect: defect, note: note, imageFilename: filename)
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

private struct VehicleCameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VehicleCameraPicker
        init(parent: VehicleCameraPicker) { self.parent = parent }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onCancel() }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            guard let image = info[.originalImage] as? UIImage else { parent.onCancel(); return }
            parent.onImage(image)
        }
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
        .sheet(isPresented: $showingCamera) {
            VehicleCameraPicker(onImage: { image in
                photoData = image.jpegData(compressionQuality: 1.0)
                showingCamera = false
                if photoData == nil { errorMessage = "Не удалось подготовить фотографию." }
            }, onCancel: { showingCamera = false })
        }
        .sheet(item: $selected) { record in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if let data = try? Data(contentsOf: VehicleInspectionStorage.directory().appendingPathComponent(record.imageFilename)),
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
