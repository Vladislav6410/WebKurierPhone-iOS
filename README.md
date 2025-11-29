# WebKurierPhone-iOS — Native iOS Client for the WebKurier Ecosystem

**WebKurierPhone-iOS** is the official native iOS application for the WebKurier platform.  
It provides a high-performance mobile interface for all communication, translation, voice, telephony, geodesy previews, WebCoin wallet interactions, and AI agents integrated through WebKurierPhoneCore and WebKurierCore.

This app is built with:
- Swift / SwiftUI
- WebRTC stack (for calls & voice translation)
- Secure local storage
- REST & WebSocket connection to PhoneCore & Core
- Adaptive UI layouts for iPhone & iPad
- Native media handling for DreamMaker

---

# 1. Role in the Ecosystem (Hierarchy Level 3)

```text
Level 0 — WebKurierHybrid (orchestrator)
Level 1 — WebKurierCore (gateway & terminal)
Level 2 — WebKurierPhoneCore (communication hub)
Level 2 — WebKurierVehicleHub (transport & geodesy)
Level 2 — WebKurierChain (blockchain & tokens)
Level 2 — WebKurierSecurity (security)
Level 3 — WebKurierPhone-iOS (THIS REPOSITORY)
Level 3 — WebKurierPhone-Android
Level 4 — WebKurierSite
Level 5 — WebKurierX

iOS serves as a direct user client, providing:

User → iOS App → PhoneCore/Core → Domain Hubs → Core → iOS App


⸻

2. App Capabilities

2.1. Translation & Communication
	•	Real-time translation (text/voice)
	•	Auto language detection
	•	Document & image translation
	•	Full integration with TranslatorAgent and VoiceAgent

2.2. Voice & Calls (WebRTC)
	•	Voice calls between users
	•	Live bilingual subtitles
	•	Audio processing on-device
	•	High-quality echo cancellation

2.3. Lessons A1–C1
	•	Multilingual practice tool
	•	Listening/reading exercises
	•	Speaking mode (mic → STT → translation)

2.4. Emotional & Social Agents
	•	Romantic assistant
	•	HR interview simulations
	•	Marketing notifications
	•	Cafe ordering flows

2.5. DreamMaker Media
	•	Generate images, audio & video
	•	Local preview, save, export

2.6. WebCoin Wallet
	•	View balance
	•	Rewards from tasks & interactions
	•	Transactions synced with Chain

2.7. Geodesy & VehicleHub Support
	•	Receive mission summaries
	•	Receive warnings/alerts during flights
	•	Live status streams (text only)
	•	PV/3D previews (static render)

⸻

3. Repository Structure (High-Level)

WebKurierPhone-iOS/
├── App/
│   ├── WebKurierPhoneApp.swift
│   ├── Scenes/
│   │   ├── HomeView.swift
│   │   ├── TranslatorView.swift
│   │   ├── VoiceCallView.swift
│   │   ├── LessonsView.swift
│   │   ├── WalletView.swift
│   │   ├── CafeView.swift
│   │   ├── RomanticView.swift
│   │   ├── HRView.swift
│   │   ├── DreamMakerView.swift
│   │   └── SettingsView.swift
│   ├── Components/
│   │   ├── AgentTile.swift
│   │   ├── AudioButton.swift
│   │   └── FilePicker.swift
│   ├── Services/
│   │   ├── PhoneCoreAPI.swift
│   │   ├── CoreGateway.swift
│   │   ├── WebRTCClient.swift
│   │   ├── AudioEngine.swift
│   │   └── LocalizationManager.swift
│   ├── Models/
│   │   ├── TranslationModel.swift
│   │   ├── VoiceCallModel.swift
│   │   ├── LessonModel.swift
│   │   └── WalletModel.swift
│   └── Utils/
│       ├── ImageLoader.swift
│       ├── FileProcessor.swift
│       └── SecureStore.swift
├── Resources/
│   ├── Localizations/
│   ├── AppIcons/
│   ├── Sounds/
│   └── Media/
├── Config/
│   ├── env.example.plist
│   └── endpoints.json
└── Docs/
    ├── ARCHITECTURE.md
    ├── API_REFERENCE.md
    └── BUILD_GUIDE.md


⸻

4. Integration Model

PhoneCore Integration

The app relies on:
	•	REST for translation, lessons, wallet, cafe
	•	WebSocket for real-time voice & subtitles
	•	WebRTC for calls

Core Integration

Used for:
	•	account/session management
	•	terminal-based commands (restricted)
	•	agent discovery + UI routing

Chain Integration

Indirect:
	•	balance fetch
	•	reward history
	•	transaction confirmation

VehicleHub Integration

Receive-only:
	•	flight warnings
	•	mission summaries
	•	telemetry notifications

Security Integration
	•	URL safety
	•	file upload scanning (via API)
	•	phishing-safe message filters

⸻

5. CI/CD Policy

The iOS app build is controlled by WebKurierHybrid via:
	•	Xcode Cloud or GitHub Actions (Fastlane)
	•	Code signing policies
	•	App Store deployment channel
	•	TestFlight distribution
	•	Secrets stored ONLY in Hybrid

⸻

6. Agent Glossary (EN + RU translations only)

TranslatorAgent — Переводчик
VoiceAgent — Голосовой ассистент
PhoneAgent — Телефония
LessonsAgent — Уроки A1–C1
RomanticAgent — Романтический собеседник
MemoryAgent — Память
DreamAgent — Генератор медиа
CafeAgent — Агент кафе и заказов
WalletAgent — Кошелёк WebCoin
MarketingAgent — Маркетолог
HRAgent — HR-агент
SecurityAgent — Агент безопасности


⸻

7. Governance

WebKurierPhone-iOS is built and maintained by
Vladyslav Hushchyn (VladoExport)
Germany, EU.

⸻


