import SwiftUI
import UniformTypeIdentifiers

struct FilePicker: View {

    let onPick: (URL) -> Void
    @State private var isPresented = false

    var body: some View {
        Button("Select File") {
            isPresented = true
        }
        .fileImporter(
            isPresented: $isPresented,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                onPick(url)
            }
        }
    }
}