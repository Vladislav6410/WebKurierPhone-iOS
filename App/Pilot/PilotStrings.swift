import Foundation

/// Respects LocalizationManager's language. The base Copilot table is Russian
/// for this pilot; future <language>.lproj/Copilot.strings override it per key.
struct PilotStrings {
    let language: String

    func callAsFunction(_ key: String) -> String {
        let fallback = Bundle.main.localizedString(forKey: key, value: key, table: "Copilot")
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return fallback }
        return bundle.localizedString(forKey: key, value: fallback, table: "Copilot")
    }
}
