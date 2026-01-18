# MediaCleaner — iOS Module

Privacy-first media cleanup assistant for WebKurierPhone-iOS.

## Purpose
MediaCleaner analyzes the user’s photo library **metadata only** to:
- detect screenshots
- estimate duplicates
- flag potential blur
- estimate space savings (heuristics)

No raw images or video bytes are uploaded.

---

## Data Flow (Strict)

User → iOS App (MediaCleanerView)  
→ MediaCleanerService  
→ MediaCleanerScanStub (local metadata scan)  
→ MediaCleanerAPI (Core)  
→ Core → Chain (reward, if applicable)

The iOS client never talks directly to Chain or Security.

---

## Permissions
Required iOS permissions:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription` (future, optional)
- `NSMicrophoneUsageDescription` (unrelated, used by other modules)

Authorization mode:
- `.readWrite` (Photos)
- `.limited` supported

---

## Modes
- `local_only` (default): scan + summary only
- `sync_enabled` (future): allow server-side sync or cross-device aggregation

The `mode` flag is forward-compatible.

---

## Rewards
- Coins are awarded based on **estimated freed bytes**
- Actual deletion/compression is **not** performed automatically
- Final logic is enforced server-side (Core → Chain)

---

## Security Notes
- No PII beyond userId/deviceId
- deviceId = `identifierForVendor`
- Summaries contain counts and byte estimates only

---

## Extensibility
Planned upgrades:
- Real duplicate hashing (local index)
- Blur detection via on-device ML
- User-confirmed cleanup actions
- Before/After comparison
- Batch approval UI

---

## Files
- `App/Scenes/MediaCleanerView.swift`
- `App/Services/MediaCleanerService.swift`
- `App/Services/MediaCleanerAPI.swift`
- `App/Services/MediaCleanerScanStub.swift`
- `App/Models/MediaCleanerResultsSummary.swift`
- `App/Models/MediaCleanerSession.swift`

---

## Compliance
MediaCleaner complies with:
- Apple Photos privacy guidelines
- WebKurier architecture boundaries
- GDPR (no raw media transfer)

Any deviation invalidates release.