import Foundation
import Combine

final class LocalizationManager: ObservableObject {

    @Published var currentLanguage: String

    private let supportedLanguages = ["de", "en", "pl", "ru", "uk"]
    private let storageKey = "WebKurier.SelectedLanguage"

    init() {
        if let saved = UserDefaults.standard.string(forKey: storageKey) {
            self.currentLanguage = saved
        } else {
            self.currentLanguage = Locale.current.language.languageCode?.identifier ?? "en"
        }
    }

    func setLanguage(_ lang: String) {
        guard supportedLanguages.contains(lang) else { return }
        currentLanguage = lang
        UserDefaults.standard.set(lang, forKey: storageKey)
    }

    func isSupported(_ lang: String) -> Bool {
        supportedLanguages.contains(lang)
    }
}