# WebKurierPhone-iOS

iOS client for the multilingual AI translator and German A1–C1 learning platform.  
Built with **SwiftUI**, **Combine**, and connected to the unified backend **WebKurierPhoneCore**.

---

## 🌍 Overview

**Languages available now:** 🇬🇧 English, 🇩🇪 German, 🇺🇦 Ukrainian, 🇷🇺 Russian  
More EU languages coming soon.

WebKurierPhone-iOS provides:
- real-time translation (text → voice → conversation);
- German A1–C1 lessons with images, audio, dialogs and quizzes;
- GPT-powered AI chat for practicing speaking and grammar;
- progress tracking and daily training;
- voice practice with STT/TTS (speech recognition and synthesis);
- seamless sync with Android and WebKurierPhoneCore.

Designed for everyday use, job interviews, study, immigration, and Jobcenter requirements.

---

## 🧱 Features

- 🔁 **Instant translation** (bidirectional)  
- 🎓 **German A1–C1** full program with exercises  
- 🎤 **Speech practice** — repeat, record, compare  
- 💬 **AI Chat (GPT)** — real-time teacher  
- 🚩 **Flag-based language picker**  
- 📚 **Vocabulary builder**  
- 📊 **Learning analytics**  
- 🌙 **Dark/Light theme** (auto system mode)

---

## 🏗 Project Structure

```text
WebKurierPhone-iOS/
    ├─ WebKurierPhone/
    │   ├─ App/
    │   │   └─ WebKurierPhoneApp.swift      # entry point
    │   ├─ Core/
    │   │   ├─ Networking/                  # API → PhoneCore
    │   │   ├─ Models/                      # DTOs / lesson models
    │   │   ├─ TTS/ STT/                    # speech systems
    │   │   └─ Localization/                # flags, L10N strings
    │   ├─ Screens/
    │   │   ├─ TranslateView.swift
    │   │   ├─ LessonsView.swift
    │   │   ├─ LessonDetailView.swift
    │   │   ├─ AIChatView.swift
    │   │   ├─ CallView.swift               # future WebRTC
    │   │   └─ SettingsView.swift
    │   └─ Resources/
    │       ├─ lesson_media/
    │       └─ flags/
    ├─ Package.swift
    ├─ README.md
    └─ LICENSE


⸻

🔗 Backend Integration

All AI and translation logic is processed through WebKurierPhoneCore, not on the device.

App → PhoneCore API → AI Provider (OpenAI, local model) → PhoneCore → App

Advantages:
	•	no API keys in iOS bundle
	•	centralized limits and analytics
	•	easy to switch AI models (GPT, local, hybrid)

⸻

🛠 Installation (Dev)
	1.	Clone repository:

git clone https://github.com/<your-username>/WebKurierPhone-iOS.git

	2.	Open project:

open WebKurierPhone-iOS/WebKurierPhone.xcodeproj

	3.	Set backend URL in:

WebKurierPhone/Core/Networking/ApiConfig.swift

	4.	Run on simulator or device.

⸻

🚀 Roadmap
	•	WebRTC for call translation
	•	Offline phrasebook and lessons
	•	Full EU language support
	•	Flashcards generator (AI-based)
	•	Jobcenter PDF reports via PhoneCore
	•	Shared progress across devices

⸻

📄 License

Made in Germany 🇩🇪
© 2025 Vladyslav Hushchyn — WebKurier Project.
License to be defined in LICENSE.md.

---

# Готов продолжать

Если хочешь — выбирай, что делаем следующим:

### **Вариант A — Полная структура уроков A1–C1**
С логикой:
- lesson.json  
- picture.mp4 / image.jpg  
- native audio  
- упражнения (test, fill-in, dialog)

### **Вариант B — API для PhoneCore**
Endpoints:
- `/translate`
- `/lesson/get`
- `/lesson/submit`
- `/chat/gpt`
- `/call/start`

### **Вариант C — Сразу Android структуру (папки + каркас)**

Напиши: **«Начинаем с A/B/C»**.

