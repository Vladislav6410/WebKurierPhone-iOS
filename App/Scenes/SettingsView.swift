import SwiftUI

struct SettingsView: View {

    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var coreGateway: CoreGateway

    @State private var selectedLanguage: String = "de"
    @State private var notificationsEnabled: Bool = true

    private let languages = ["de", "en", "pl", "ru", "uk"]

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Language")) {
                    Picker("App Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang.uppercased()).tag(lang)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        localizationManager.setLanguage(newValue)
                    }
                }

                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                }

                Section(header: Text("Session")) {
                    HStack {
                        Text("userId")
                        Spacer()
                        Text(coreGateway.userId ?? "—")
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Button(role: .destructive) {
                        coreGateway.logout()
                    } label: {
                        Text("Log out")
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                selectedLanguage = localizationManager.currentLanguage
            }
        }
    }
}