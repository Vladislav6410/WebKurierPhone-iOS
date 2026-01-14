import SwiftUI

struct SettingsView: View {

    @State private var selectedLanguage: String = "de"
    private let languages = ["de", "en", "pl", "ru", "uk"]

    @State private var notificationsEnabled: Bool = true

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Language")) {
                    Picker("App Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang.uppercased()).tag(lang)
                        }
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }

                Section {
                    Button(role: .destructive, action: logout) {
                        Text("Log out")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private func logout() {
        // Placeholder: session reset via CoreGateway
        print("Logout requested")
    }
}