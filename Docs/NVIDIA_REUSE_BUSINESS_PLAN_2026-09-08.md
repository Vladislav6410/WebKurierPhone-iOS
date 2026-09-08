# NVIDIA Reuse Business Plan — WebKurierPhone-iOS

Audit date: 2026-09-08

Historical baseline: `archive/pre-nvidia-reuse-audit-2026-09-08`.

## Strategic decision

**NO DIRECT NVIDIA SDK DEPENDENCY RECOMMENDED FOR iOS.**

The native iOS client should remain Swift/SwiftUI/WebRTC and consume NVIDIA-backed speech, AI, video or geospatial capabilities through PhoneCore/Core APIs. NVIDIA runtime dependencies belong on Jetson/server systems, not in the iOS app.

## Reuse opportunities

### 1. Riva / Speech NIM through PhoneCore

If PhoneCore validates NVIDIA Riva/NIM for STT/TTS/translation, iOS can use the same existing API contract without knowing which provider served the request.

Status: **INDIRECT / PROVIDER-TRANSPARENT**.

### 2. JPS/VST mobile patterns — REFERENCE ONLY

Jetson Platform Services includes a reference AI-NVR mobile application and device call flows. These may be studied for camera/video control UX if WebKurier later exposes Jetson video services, but should not be copied as core application architecture.

Status: **DESIGN/INTERACTION REFERENCE ONLY**.

## Business impact

Keep the mobile client small, portable and independent of NVIDIA release cycles. All acceleration remains behind stable WebKurier APIs.

## Guardrails

- no direct Jetson credentials in iOS;
- no direct NVIDIA service secrets;
- no device-control bypass around Core/Security;
- one UI/API integration → one branch → one PR.

## Official references

- https://docs.nvidia.com/jetson/jps/
- https://docs.nvidia.com/nim/speech/latest/nmt/index.html
