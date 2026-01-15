# Sounds

This directory stores short audio assets used by WebKurierPhone-iOS.

Use cases:
- UI feedback (tap, success, error)
- Call connect / disconnect tones
- Notification sounds (local only)

Guidelines:
- Prefer .wav or .caf for short UI sounds
- Keep files short (<2 seconds)
- Normalize volume to avoid clipping
- No copyrighted audio

Playback is handled via AVFoundation.