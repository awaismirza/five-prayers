# Contributing to Five Prayers

Thank you for your interest in contributing to Five Prayers. This project is a calm, private iPhone app for helping Muslims track the five daily prayers.

## Project Values

- Keep the tone respectful, warm, and encouraging.
- Preserve user privacy. Do not add ads, trackers, analytics SDKs, or social profiling.
- Keep prayer data local-first unless a future change explicitly introduces opt-in sync.
- Avoid guilt-heavy language. Prefer terms like Prayed, Missed, Made Up, Remaining Missed, and Progress.
- Do not present the app as a religious authority. Prayer times are practical estimates and should defer to local trusted sources.

## Development Setup

1. Open `FivePrayers.xcodeproj` in Xcode.
2. Use the `FivePrayers` scheme.
3. Build for iOS 17.6 or later.
4. For command-line verification, run:

```sh
xcodebuild -project FivePrayers.xcodeproj -scheme FivePrayers -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

If local signing is configured, you can also build and run on a simulator or device from Xcode.

## Repository Structure

- `FivePrayers/` contains the SwiftUI iOS app.
- `SPEC.md` documents product behavior, architecture, data models, and recent changes.
- `index.html` is the static product website.
- `docs/` contains website support docs and shared image assets.

## Making Changes

- Read `SPEC.md` before changing product behavior.
- Keep changes focused and avoid unrelated refactors.
- Prefer existing SwiftUI patterns and theme tokens.
- Do not remove SwiftData models or fields without a migration plan.
- Do not change the bundle identifier.
- Do not add remote push notifications, backend services, ads, or tracking.
- For website changes, keep `index.html` dependency-free and responsive.

## Testing Checklist

Before opening a pull request, verify:

- The app builds successfully.
- Existing prayer logs still load.
- Home reflects prayer state based on the current time.
- Upcoming prayers cannot be marked early.
- Progress counts Prayed, Missed, Made Up, and Remaining Missed correctly.
- Notification permission prompts and local prayer reminders still work.
- Dark mode remains readable.
- The static website still renders without external dependencies.

## Pull Requests

In your pull request, include:

- A short summary of what changed.
- Screenshots or screen recordings for UI changes.
- Any data model or migration notes.
- Build/test commands you ran.
- Known limitations or follow-up work.

## Documentation

Update `SPEC.md` when changing app behavior, data models, notification behavior, or user-facing terminology. Update `docs/README.md` when changing website deployment or App Store URLs.

