import SwiftUI

final class ImageLoader: ObservableObject {

    @Published var image: Image?

    func load(from url: URL) {
        DispatchQueue.global(qos: .background).async {
            guard
                let data = try? Data(contentsOf: url),
                let uiImage = UIImage(data: data)
            else {
                return
            }

            DispatchQueue.main.async {
                self.image = Image(uiImage: uiImage)
            }
        }
    }
}