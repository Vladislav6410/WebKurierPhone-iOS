import SwiftUI
import UniformTypeIdentifiers

struct FilePickerButton: View {

    let title: String
    let systemImage: String?
    let allowedTypes: [UTType]
    let onPicked: (URL) -> Void

    @State private var isPresented: Bool = false

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .foregroundStyle(.primary)
                }
                Text(title)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPresented) {
            FilePicker(allowedTypes: allowedTypes) { url in
                isPresented = false
                onPicked(url)
            }
        }
    }
}

// MARK: - Presets

extension FilePickerButton {

    static func pdf(_ onPicked: @escaping (URL) -> Void) -> FilePickerButton {
        FilePickerButton(
            title: "Select PDF",
            systemImage: "doc.text",
            allowedTypes: [.pdf],
            onPicked: onPicked
        )
    }

    static func image(_ onPicked: @escaping (URL) -> Void) -> FilePickerButton {
        FilePickerButton(
            title: "Choose Image",
            systemImage: "photo",
            allowedTypes: [.image],
            onPicked: onPicked
        )
    }
}