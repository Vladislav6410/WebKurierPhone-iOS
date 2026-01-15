# WebKurierPhone-iOS — Architecture

## Role in the WebKurier Ecosystem

WebKurierPhone-iOS is a **Level 3 client application**.

Routing rule (mandatory):

User → iOS App → WebKurierCore / WebKurierPhoneCore  
→ Domain Hubs (Chain, Security, VehicleHub)  
→ Core → iOS App

The iOS client never communicates directly with:
- Chain
- Security
- VehicleHub
- Hybrid

All access is mediated by Core and PhoneCore.

---

## Responsibility Boundaries

### iOS Client
- UI rendering (SwiftUI)
- Local audio handling
- Secure local storage (Keychain)
- Session presence (read-only)
- Media preview

### WebKurierCore
- Authentication & session control
- Agent routing
- Wallet requests (signed)
- User cabinet
- Language & preferences

### WebKurierPhoneCore
- Voice calls (WebRTC)
- STT / TTS
- Realtime translation
- Lessons A1–C1

---

## Security Principles

- No secrets stored in app bundle
- Tokens stored only in Keychain
- All uploads scanned via Security API
- Wallet operations validated by Chain
- Short-lived access tokens only

---

## Update & Deployment

- CI/CD controlled by WebKurierHybrid
- App Store & TestFlight builds only
- No local signing keys allowed

---

## Forbidden Actions

- Direct blockchain access
- Direct VehicleHub access
- Embedded API keys
- Cross-domain shortcuts

Violation of architecture rules invalidates the build.