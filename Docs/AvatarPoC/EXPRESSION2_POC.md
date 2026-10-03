# bitHuman Expression 2 avatar PoC

Isolated iPhone proof: permitted demo avatar, prepared 16 kHz speech, lip-synced frames, local playback.

This is not the AI teacher. It does not call STT, TTS, RAG, OpenAI, or WebKurierCore.

## Boundary

`AvatarPoCView` -> `BitHumanAvatarAdapter` -> `Expression2AvatarSession` -> Expression2.

Only `Expression2AvatarSession.swift` imports Expression2.

## Dependency

- Package: `https://github.com/bithuman-product/homebrew-bithuman.git`
- Version pin: `from: 2.20.0` (verified tag `v2.20.0`)
- Product: `Expression2`
- Import: `Expression2`
- Minimum iOS: 16
- Xcode: 26 or newer, per current bitHuman iOS docs
- Simulator: Expression 2 is documented to run; slices are arm64 only (`EXCLUDED_ARCHS` excludes simulator x86_64)
- Physical iPhone: supported; not executed in this change

## Assets

Not committed. First run downloads the documented no-account sample:

- avatar `A23WJF0199.imx` (`wise-pup`)
- shared engine `mac-arm64-1.0.0.engine`
- `demo_speech_16k.wav`

Docs describe the first-run payload as about 370 MB. Files stay in Application Support.

## Secret

`BITHUMAN_API_SECRET` is read from the process environment only.

Do not put it in source, Info.plist, xcconfig, fixtures, tests, docs, or logs.

Production, not implemented here: authorized backend -> temporary credential -> iOS -> Keychain. Existing architecture notes already require Keychain for tokens; this PoC does not add a second credential store.

## Out of scope

Student course navigation, lesson content, Drive links, course numbering, production STT/TTS, RAG, ChatGPT/OpenAI, Android, WebKurierCore.
