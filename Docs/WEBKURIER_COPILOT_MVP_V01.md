# WebKurier Copilot — iOS MVP v0.1

## Scope and student flow

Pilot / Week 1 only. The app starts on **Мой проект / GitHub**, with a WK wordmark
and explicit connection state. After a verified connection it selects **Мой курс**.
Students can also read the course without connecting; this does not authenticate
them or assign a project.

The only tabs are **Мой курс**, **Copilot**, **Мой проект / GitHub**.
Day 1 explains project → GitHub → website. Day 2 describes a visible page change.
Day 3 describes navigation and 2–3 pages. Each lesson opens Copilot with that day's
task and isolated conversation/draft. The result action appears in the course,
Copilot and project screens. Weeks 2–8 are locked labels, **Откроется позже**, with
no lesson data or navigation actions.

Completion is a student's session-only self-assessment. It resets when the app
process exits, does not unlock later weeks, and is not evidence of a deployment.
Drafts and conversation history also exist in memory only.

## Verified starting point

- Repository: `Vladislav6410/WebKurierPhone-iOS`.
- Authorized branch: `feat/webkurier-copilot-mvp-v01`.
- Starting HEAD: `b705b903c3a0484581c3aa01b2da580f97c13e94`.
- Only pre-existing local change: `Docs/ARCHITECTURE.md`; preserved and excluded.
- Its starting SHA-256: `EAC5EE4743A029BC7999134371689B419F041D9BD9AC5DAD5509800F0A5B1DD0`.
- Existing CoreGateway bootstrap creates a placeholder guest, not verified GitHub
  authentication. Existing endpoints use `.example` hosts and do not define a
  Copilot or GitHub OAuth contract. They are not used by the pilot.
- The repository had no Xcode project, package, tests or checked-in CI workflow.
  Legacy files also contain duplicate types and incompatible service APIs, so
  compiling all existing sources is not a valid pilot build configuration.

## GitHub boundary: unavailable until configured

`PilotGitHubConnecting.connect()` is the future adapter boundary. It must return
`PilotGitHubSession` only after WebKurier's backend has verified the student's
GitHub identity and assignment. The client displays only returned identity,
repository name and optional verified project status. Nothing is fabricated.

The shipped `UnavailablePilotGitHubService` throws `notConfigured`. The state
machine supports not connected → connecting → connected/error, retries after an
error, and rejects concurrent attempts. Connected state is never returned by the
shipped service. Course preview remains available after an error.

Required before enabling real connection:

1. A registered GitHub OAuth/GitHub App and approved client configuration, callback
   URL and minimal permission scopes for the pilot's authorized repository.
2. A verified WebKurier Core/backend contract for starting/completing connection,
   validating state/PKCE as applicable, exchanging credentials, session validation,
   repository assignment and revocation/logout. Use the system authentication
   session for browser-based login when implementing the adapter.
3. Backend-managed GitHub credentials and project authorization. Any device-side
   WebKurier session material must use the existing secure storage boundary, once
   its contract is verified; no student token entry or embedded client secrets.

## Copilot boundary: unavailable until configured

`PilotCopilotServing` accepts the selected lesson, verified project context,
message and that lesson's conversation. The shipped implementation is explicitly
unavailable: the UI shows the lesson and allows an unsent draft, but disables Send.
There are no simulated teacher replies or claims that a site was edited.

Future flow: iPhone → controlled WebKurier backend through CoreGateway → AI →
authorized student GitHub project. A backend adapter still needs a verified
request/response and error contract, session authorization, repository permission
checks, history limits, cancellation and idempotency semantics for project writes.
The current protocol is a client boundary, not an invented HTTP endpoint. Its
conversation result does not establish deployment success. Failed sends retain
the draft; the UI advises checking the site before retrying a requested edit.

No provider selection, model names, API keys, tuning controls or agent settings
appear in the student UI. No AI-provider SDK or network dependency is added.

## Website URL: unconfigured

No verified student website URL was found. `PILOT_PROJECT_SITE_URL` is an optional
key read from the app's final Info.plist, with **no default**. A release owner must
supply the verified course/site address through the build configuration (for
example, an `INFOPLIST_KEY_PILOT_PROJECT_SITE_URL` build setting for the generated
Info.plist). No student-editable URL field exists.

The validator requires an absolute HTTPS URL with a dotted host, no credentials,
no whitespace, and no nonstandard port. It rejects reserved placeholder hosts
ending in `.example`, `.invalid`, or `.localhost`. Shape validation does not prove
ownership: trusted configuration must establish that separately. This static
configuration represents the pilot training site; per-student site assignments
require a verified backend contract before expansion.

Missing or invalid configuration disables **Посмотреть результат на сайте** and
explains why. Valid configuration uses SwiftUI `openURL`, the normal iOS browser
mechanism, and reports a refused open. Test fixture URLs are not app defaults.

## Source and localization layout

- `App/PilotCore`: Foundation-only course state, GitHub transitions, URL validation
  and service contracts. `Package.swift` allows `swift test` independently of UIKit.
- `App/Pilot`: SwiftUI views and observable presentation state. Services are
  constructor-injected; shipped composition uses only unavailable adapters.
- `Resources/Localizations/Copilot.strings`: centralized Russian pilot copy.
  `PilotStrings` respects `LocalizationManager.currentLanguage` and supports future
  `pl.lproj`, `de.lproj`, `en.lproj` tables, with fallback per missing key. Include
  those new resources in the build specification when adding translations.
- `App/WebKurierPhoneApp.swift` now opens the pilot. Legacy root/tab code remains
  under `#if !PILOT_MVP`; the legacy home, scenes, services and resources are retained.
- `project.yml` explicitly includes only pilot sources and LocalizationManager.
  The generated pilot Info.plist has no legacy media permissions or endpoints.

## Build and validation

On macOS, install Xcode and XcodeGen, then run from the repository root:

```sh
swift test
xcodegen generate --spec project.yml
xcodebuild build -project WebKurierPilot.xcodeproj -scheme WebKurierPilot \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
xcodebuild -showdestinations -project WebKurierPilot.xcodeproj -scheme WebKurierPilot
# Use an available iPhone simulator ID from the preceding command:
xcodebuild test -project WebKurierPilot.xcodeproj -scheme WebKurierPilot \
  -destination 'platform=iOS Simulator,id=<available-simulator-id>' CODE_SIGNING_ALLOWED=NO
```

The [XcodeGen project specification](https://github.com/yonaskolb/XcodeGen/blob/master/Docs/ProjectSpec.md)
defines the isolated app and its store test target. Generated projects and build
outputs are ignored. Signing is disabled by default; the release owner must supply
the actual bundle ID/team/signing configuration and final app icon for devices or
distribution. The WK wordmark is temporary, not a copied third-party logo.

`Tests/PilotCoreTests` contains 14 tests for course structure, day navigation,
session completion, locked future weeks, GitHub transitions and unavailable
services, and URL validation. `Tests/PilotStoreTests` contains 6 app-hosted tests
for connection handling, project assignment gating, concurrent attempts, failed
send retry and replies arriving after switching lessons. All fake connected
services exist only in test sources.

`.github/workflows/pilot.yml` runs package and simulator tests on relevant PRs to
main with read-only repository permissions. A configured workflow is not evidence
that it passed; inspect its run result separately.

Available Windows checks:

```powershell
./Scripts/Test-PilotRepository.ps1
git diff --check
```

During implementation both checks passed. The script checks localization syntax,
duplicate/missing keys, dynamic lesson/status keys, configured source paths and
the absence of default network URLs in pilot code. It does not compile or execute
Swift. Swift, Xcode, XcodeGen and an iOS simulator were unavailable on this machine.

**iOS BUILD NOT RUN — macOS/Xcode required.**
Swift/XCTest and visual/device/accessibility validation were not run locally.
Live OAuth, AI replies, GitHub project writes and website deployment are unavailable
until the prerequisites above are supplied and integration-tested.

## Security and exclusions

No credentials, provider keys, OAuth secrets, production endpoints or fabricated
website addresses are introduced. Unavailable services perform no network calls.
No unrelated repository is modified and no merge is authorized. The pre-existing
`Docs/ARCHITECTURE.md` modification is not part of this change.

Slack, Drive, Dropbox, Calendar, Gmail, payments, subscriptions, wallets, voices,
voice-speed settings, advanced settings and Weeks 2–8 functionality are out of
scope and not exposed by this pilot target.
