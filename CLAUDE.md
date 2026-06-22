# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

HabitTracker is an iOS app built with SwiftUI and SwiftData. It currently contains the unmodified Xcode "App" template (the `Item`/timestamp list scaffold) and has not yet been built out into a habit tracker — expect to replace the template code (`Item`, `ContentView`) as the first real feature work.

- Bundle identifier: `com.namle.HabitTracker`
- Deployment target: iOS 26.5, Swift 5.0
- Scheme: `HabitTracker`

## Commands

Build and test are driven through `xcodebuild` (no Swift Package Manager / CocoaPods / external dependencies).

**Two environment gotchas on this machine:**
- The active developer dir is Command Line Tools, so prefix every command with `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (or run `sudo xcode-select -s /Applications/Xcode.app` once).
- Deployment target is iOS 26.5, so the simulator must run a 26.5 runtime. The iPhone 16 sim is on an older runtime — use **iPhone 17**. List valid destinations with `xcrun simctl list devices available | grep iPhone`.

```bash
# Build
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild build -project HabitTracker.xcodeproj -scheme HabitTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# Run only the unit tests (Swift Testing) — fast and reliable headless
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild test -project HabitTracker.xcodeproj -scheme HabitTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:HabitTrackerTests

# Run a single test, e.g. one test function
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild test -project HabitTracker.xcodeproj -scheme HabitTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:HabitTrackerTests/streakTodayNotDoneDoesNotBreakIt
```

Swift Testing console output is sparse; for definitive pass/fail read the result bundle:
`xcrun xcresulttool get test-results summary --path build/Logs/Test/*.xcresult`.

The project uses **file-system-synchronized groups** (Xcode 16+/objectVersion 77): new `.swift`
files dropped under `HabitTracker/**` or `HabitTrackerTests/**` are auto-added to the target — no
`project.pbxproj` edits needed. Day-to-day it's normally built and run from Xcode.

## Architecture

The app is a habit tracker implemented from `habit-tracker-design/Habit Tracker.dc.html`. It deliberately avoids scattering `@Query` and per-frame computation; understand these layers before changing behavior:

**Data (`Models/`)** — three SwiftData `@Model`s registered in `Schema([Habit, HabitLog, MoodEntry])` in `HabitTrackerApp.swift`. `Habit` stores enums as raw strings and exposes a typed `spec`. `HabitLog` is one row per `(habit, dayKey)`; `MoodEntry` one per day (`dayKey` unique). Local-only on-disk persistence; container `fatalError`s on failure. **Any new `@Model` must be added to the `Schema` list.**

**Derivation (`Core/`)** — `HabitDerivations` holds pure, side-effect-free functions (streak/best/rate/heat/perfect-days/…) ported verbatim from the prototype, each taking an explicit `today` for determinism. They scan up to 400 days, so **they must never be called from a SwiftUI `body`.** `DayKey` does all day bucketing via local "YYYY-MM-DD" strings and converts Foundation's 1=Sun weekday to the prototype's 0=Sun.

**Store (`Store/HabitStore.swift`)** — the single source of truth. An `@Observable` that loads habits/logs/moods into in-memory indices once, exposes **cached** `statsByHabit` / `global` (recomputed only on mutation via `recompute()`), and persists through idempotent upserts. Views read cached stats and O(1) lookups; they never query or derive directly. `logIndex` is intentionally observation-tracked (not `@ObservationIgnored`) because Today reads completion state from it.

**UI (`Theme/`, `Components/`, `Screens/`, `RootView.swift`)** — `ThemeManager` (light/dark tokens, persisted) and the store are injected via `.environment(...)`; sheets re-inject them because sheets don't inherit the observable environment. Nunito is substituted with `.system(design: .rounded)` (no bundled fonts).

Tests live in `HabitTrackerTests/HabitDerivationsTests.swift` and exercise the pure derivation layer with fixed-date in-memory fixtures — the highest-value tests, and the place to add coverage when changing the math.

## Tests

- `HabitTrackerTests/` uses the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`), not XCTest.
- `HabitTrackerUITests/` uses **XCTest** (`XCUIApplication`) for UI and launch-performance tests.


Use context7 to check up-to-date docs when needed implementing new libraries or frameworks, or adding feature using them.


# Project Workflow

## Simple Tasks

- Read relevant code first
- Implement directly
- Run tests
- Self review

## Medium Tasks

- Create plan
- Review plan
- Implement
- Run tests
- Review implementation

## General Rules

- Prefer simple solutions
- Follow existing patterns
- Avoid unnecessary abstractions
- Keep changes minimal
- Do not expand scope

## Testing

- Run relevant tests before finishing
- Add tests for new logic when appropriate
- Report test results
