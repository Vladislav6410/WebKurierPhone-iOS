import SwiftUI

enum SceneRoute: Hashable {
    case translator
    case voiceCall
    case lessons
    case wallet
    case cafe
    case romantic
    case hr
    case dreamMaker
    case settings
}

final class SceneRouter: ObservableObject {

    @Published var path: [SceneRoute] = []

    func push(_ route: SceneRoute) {
        path.append(route)
    }

    func pop() {
        _ = path.popLast()
    }

    func reset() {
        path.removeAll()
    }
}

struct SceneDestination: View {

    let route: SceneRoute

    var body: some View {
        switch route {
        case .translator:
            TranslatorView()
        case .voiceCall:
            VoiceCallView()
        case .lessons:
            LessonsView()
        case .wallet:
            WalletView()
        case .cafe:
            CafeView()
        case .romantic:
            RomanticView()
        case .hr:
            HRView()
        case .dreamMaker:
            DreamMakerView()
        case .settings:
            SettingsView()
        }
    }
}