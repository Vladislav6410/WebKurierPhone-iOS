# WebKurierPhone-iOS — Build Guide

This guide defines **how the iOS client is built, signed, and delivered**.
All steps must respect WebKurier security and responsibility boundaries.

---

## 1. Build Ownership

Build & distribution are controlled by:
- **WebKurierHybrid** (CI/CD, secrets, signing)
- NOT by local developer machines

Local builds are for development only.

---

## 2. Requirements

- macOS with Xcode (latest stable)
- iOS SDK 16+
- Apple Developer Account (managed by Hybrid)
- No local signing keys stored permanently

---

## 3. Local Development Build

1. Clone repository:
   ```bash
   git clone git@github.com:WebKurier/WebKurierPhone-iOS.git

	2.	Open project:

open WebKurierPhone-iOS.xcodeproj


	3.	Create local env file:
	•	Copy Config/env.example.plist
	•	Rename to env.plist
	•	Do NOT commit this file
	4.	Select simulator or device
	5.	Run ▶︎

Local builds:
	•	may use mock data
	•	must never access production Chain or Wallet

⸻

4. CI/CD Build (Authoritative)

CI/CD is executed via WebKurierHybrid:
	•	GitHub Actions / Xcode Cloud
	•	Fastlane (if enabled)

Pipeline stages:
	1.	Lint & static analysis
	2.	Build (Debug / Release)
	3.	Code signing (managed certificates)
	4.	TestFlight upload
	5.	App Store release (manual approval)

The iOS repo:
	•	does NOT store signing certificates
	•	does NOT store App Store credentials

⸻

5. Versioning

Versioning rules:
	•	MARKETING_VERSION → semantic (e.g. 1.2.0)
	•	CURRENT_PROJECT_VERSION → auto-increment (CI)

Manual version bumps are discouraged.

⸻

6. Security Checklist (Mandatory)

Before any release:
	•	No hardcoded tokens
	•	No debug endpoints enabled
	•	All uploads routed via Core
	•	Wallet actions read-only unless signed
	•	Logs contain no PII
	•	App reviewed against ARCHITECTURE.md

Failure to meet checklist → build rejected.

⸻

7. Forbidden Practices
	•	Direct calls to Chain
	•	Direct calls to Security
	•	Direct calls to VehicleHub
	•	Embedding secrets in Swift code
	•	Bypassing CoreGateway

Any violation invalidates the release.

⸻

8. Support & Handover

This repository is:
	•	client-only
	•	replaceable
	•	stateless by design

Business logic always lives in:
	•	WebKurierCore
	•	WebKurierPhoneCore

