# WebKurierPhone-iOS

Native iOS application for the WebKurier multilingual AI translator, German A1–C1 learning system, real-time AI calls, GPT dialog assistant, and vocabulary trainer.
Built with SwiftUI, WebRTC, AVSpeech, and WebKurierPhoneCore API.

⸻

🇬🇧 English

WebKurierPhone-iOS provides a fast and intuitive mobile interface for:
	•	AI-powered text & voice translation
	•	Real-time interpreted calls
	•	GPT-based chat and dialog practice
	•	German A1–C1 lessons (audio, images, grammar, exercises)
	•	Vocabulary trainer + spaced repetition (SRS)
	•	Speech recognition + pronunciation feedback
	•	Multilingual menu with flag icons

Fully synced with WebKurierPhoneCore.

⸻

🇩🇪 Deutsch

Native iOS-App für den mehrsprachigen WebKurier-Übersetzer, Deutschkurse (A1–C1), KI-Telefonie, GPT-Dialoge und Vokabeltrainer.
Erstellt mit SwiftUI und verbunden mit dem WebKurierPhoneCore-Backend.

⸻

🇺🇦 Українська

iOS-додаток для перекладача WebKurier, курсів німецької A1–C1, голосових дзвінків з AI-перекладом, GPT-чату та тренажера лексики.

⸻

🇷🇺 Русский

iOS-приложение для переводчика WebKurier, немецкого A1–C1, звонков с AI-переводчиком, GPT-чата и тренажёра слов.

⸻

⸻

🚀 Features

🔊 Translator
	•	Text translation
	•	Voice translation
	•	Photo → text (OCR)
	•	Auto-language detection

📞 AI Calls
	•	Real-time interpreter via WebRTC
	•	Noise reduction
	•	Adaptive audio filters
	•	Works in background mode

🎓 German A1–C1
	•	Lessons with images, audio, video
	•	Dialog simulations
	•	Grammar explanations
	•	Tests + quizzes
	•	Pronunciation trainer

🤖 GPT / AI Chat
	•	Writing + speaking mode
	•	Roleplay dialogs (job interview, doctor, landlord, etc.)
	•	Corrects grammar and pronunciation

📚 Vocabulary & Progress
	•	Flashcards
	•	Automated spaced repetition
	•	Tracking learning statistics

⸻

🏗 Tech Stack

Frontend
	•	SwiftUI
	•	Combine
	•	AVSpeechSynthesizer
	•	AVAudioEngine
	•	Speech framework
	•	Vision OCR
	•	WebRTC

Backend

Connects to:
	•	WebKurierPhoneCore
	•	WebKurierChain (login, secure storage)
	•	WebKurierSecurity (GDPR-safe encryption)

⸻

📡 API Connection

Config in:

/Sources/WebKurierApp/Config/API.swift

Example:

struct API {
    static let baseURL = "https://phonecore.webkurier.app"
}


⸻

🧱 Project Structure

WebKurierPhone-iOS
│
├── Sources/
│   ├── App/
│   │   ├── WebKurierPhoneApp.swift
│   │   ├── Navigation/
│   ├── Features/
│   │   ├── Translate/
│   │   ├── Call/
│   │   ├── Lessons/
│   │   ├── GPTChat/
│   │   └── Vocabulary/
│   ├── Models/
│   └── Utils/
│
└── Resources/
    ├── Icons/
    ├── Flags/
    └── LessonMedia/


⸻

🐳 Optional: CI/CD

GitHub Actions to build & sign iOS app (optional):

.github/workflows/ios-build.yml


⸻

🔐 Privacy & Security
	•	No data stored locally unless user approves
	•	Encrypted requests via https
	•	Fully GDPR compliant
	•	API keys stored in Keychain

⸻

📱 App Screens (будут добавлены позже)
	•	Translator
	•	Voice Call
	•	Lessons A1–C1
	•	Flashcards
	•	GPT Chat
	•	Settings
	•	Language/Flags menu

⸻

🏁 Status

Version: 0.1
State: Active development
Platform: iOS 15+
Language: Swift 5, SwiftUI

⸻

