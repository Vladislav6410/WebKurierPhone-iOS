# WebKurierPhone-iOS — API Reference

This document describes **client-side API usage rules**.
The iOS app never hardcodes endpoints logic — it consumes Core / PhoneCore APIs.

---

## 1. Core API (via CoreGateway)

Base URL:
- provided via `Config/endpoints.json`

### Authentication
Handled implicitly by Core.
The iOS client only:
- checks session presence
- triggers logout

No password handling inside the app.

### User Profile
GET /me  
Returns:
- userId
- role
- language
- wallet permissions

---

## 2. PhoneCore API (via PhoneCoreAPI)

### Translation
POST /translate

Request:
```json
{
  "text": "string",
  "source": "auto | null",
  "target": "en"
}

Response:

{
  "translatedText": "string",
  "detectedLanguage": "de"
}


⸻

Voice Calls

POST /call
WebRTC signaling is negotiated via WebSocket.

The iOS client:
	•	starts / stops call
	•	manages audio session
	•	displays subtitles

⸻

Lessons

GET /lessons?lang=de&level=A1

Response:
	•	units
	•	exercises
	•	metadata

Lessons logic lives fully in PhoneCore.

⸻

3. WebSocket Channels

Base:
	•	wss://…

Channels:
	•	/realtime — subtitles, translation stream
	•	/calls — signaling, presence

Reconnect rules:
	•	exponential backoff
	•	session revalidation via Core

⸻

4. Security API (Indirect)

The iOS client never calls Security directly.
All checks are routed through Core:
	•	file scan
	•	URL safety
	•	content validation

⸻

Error Handling

All API errors must be:
	•	logged locally (non-sensitive)
	•	surfaced as user-friendly messages
	•	never expose stack traces or raw payloads

⸻

Versioning

API compatibility is enforced by Core.
Breaking changes require:
	•	Core version bump
	•	App update via App Store

