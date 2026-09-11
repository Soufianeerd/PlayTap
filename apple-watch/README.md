# PlayTap — Apple Watch

Swift/SwiftUI source scaffold for the standalone watchOS app (see
`CLAUDE.md` and the `playtap-watch-ux` skill).

## Status: source written, project file and build NOT verified

This directory currently contains **source files only**
(`PlayTap Watch App/*.swift`, `Info.plist`, `Assets.xcassets`) — there is
no `.xcodeproj` yet, and no build of this target has been run.

**Why:** this environment has only Xcode's Command Line Tools installed
(`xcode-select -p` → `/Library/Developer/CommandLineTools`), not full
Xcode. `xcodebuild`, `xcrun simctl`, and the iOS/watchOS SDKs are all
unavailable — confirmed directly by `xcodebuild -version` and by
XcodeBuildMCP's `list_sims` both failing with
`unable to find utility "simctl"/"xcodebuild"`. There is no way to
generate a working `.xcodeproj` or compile this target without Xcode
itself; hand-writing a `.xcodeproj`/`project.pbxproj` without being able
to verify it would risk shipping a project file that looks real but
silently doesn't open or build, which is worse than not having one.

## To unblock

1. Install full Xcode (App Store, or
   `xcode-select --switch /Applications/Xcode.app/Contents/Developer`
   if already installed elsewhere) and run `sudo xcodebuild -runFirstLaunch`.
2. Open Xcode → File → New → Project → watchOS → App, name it
   `PlayTap Watch App`, bundle id `com.playtap.app.watchkitapp`
   (see `docs/ARCHITECTURE.md`), and point it at this folder so it picks
   up the existing `PlayTapWatchApp.swift` / `RootView.swift` / `Info.plist`
   / `Assets.xcassets` instead of regenerating them — or ask Claude to do
   this once XcodeBuildMCP's `discover_projs`/`build_sim` calls succeed.
3. From there, `docs/RELEASE_CHECKLIST.md` / `playtap-release-gate`
   applies as usual — a build must actually run before any watchOS
   feature is called done.

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
