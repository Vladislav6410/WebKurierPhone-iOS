import Foundation

struct TranslationModel: Identifiable {
    let id = UUID()

    let sourceText: String
    let translatedText: String
    let sourceLanguage: String?
    let targetLanguage: String
    let createdAt: Date
}