# PlayTap — Apple Watch

Swift/SwiftUI source scaffold for the standalone watchOS app (see
`CLAUDE.md` and the `playtap-watch-ux` skill).

## Status: source written, project file and build NOT verified

This directory currently contains **source files only**
(`PlayTap Watch App/*.swift`, `Info.plist`, `Assets.xcassets`) — there is
no `.xcodeproj` yet, and no build of this target has been run.

**Why:** Xcode is intentionally not installed on this local development
machine (`xcode-select -p` → `/Library/Developer/CommandLineTools`, no
full Xcode). This is a **deliberate, known environment constraint** (see
`CLAUDE.md` — "Stratégie Apple"), not a blocker to work around locally:
`xcodebuild`, `xcrun simctl`, and the iOS/watchOS SDKs are unavailable
here — confirmed directly by `xcodebuild -version` and by XcodeBuildMCP's
`list_sims` both failing with `unable to find utility
"simctl"/"xcodebuild"`. There is no way to generate a working
`.xcodeproj` or compile this target without Xcode itself; hand-writing a
`.xcodeproj`/`project.pbxproj` without being able to verify it would risk
shipping a project file that looks real but silently doesn't open or
build, which is worse than not having one.

## Where this gets resolved

Not by installing Xcode on this machine. Apple builds, native XCTest
runs, signing/provisioning, and App Store submission happen later in a
**macOS CI/build environment** that has Xcode:

1. That environment opens/creates the real `.xcodeproj` (watchOS App
   target named `PlayTap Watch App`, bundle id
   `com.playtap.app.watchkitapp` — see `docs/ARCHITECTURE.md`) pointed at
   this folder, so it picks up the existing `PlayTapWatchApp.swift` /
   `RootView.swift` / `Info.plist` / `Assets.xcassets` instead of
   regenerating them.
2. From there, `docs/RELEASE_CHECKLIST.md` / `playtap-release-gate`
   applies as usual — a real build must run before any watchOS feature is
   called done, and **before any Apple release**, no exception.

Until that CI/build environment is set up, this directory simply stays at
"source written, not yet build-verified" — that is expected, not an
error to fix locally.

## Layout

```
PlayTap Watch App/
  PlayTapWatchApp.swift   — @main App entry point
  RootView.swift          — placeholder root screen ("No active session")
  Info.plist
  Assets.xcassets/
tests/conformance/         — reserved for the XCTest conformance runner
                              (see docs/CONFORMANCE.md), empty until Phase 1B
```
