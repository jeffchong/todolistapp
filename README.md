# To-Do List

![Swift](https://img.shields.io/badge/Swift-6.0-FA7343?logo=swift&logoColor=white)
![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0D96F6?logo=swift&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-macOS-000000?logo=apple&logoColor=white)
![Release](https://img.shields.io/badge/Release-0.5%20alpha-orange)
![Xcode](https://img.shields.io/badge/Xcode-Project-147EFB?logo=xcode&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green)
![CI](https://github.com/jeffchong/todolistapp/actions/workflows/ci.yml/badge.svg)

A native SwiftUI macOS to-do list app designed to live both as a standard dock/window app and as a menu bar utility.

The app is intentionally lightweight: tasks are grouped by project, can be managed quickly from the menu bar, and persist locally as JSON while cloud sync providers are being built out.

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI
- **Platform:** macOS 15.0+
- **Persistence:** Local JSON in Application Support
- **Testing:** XCTest
- **Cloud Sync:** CloudKit and OneDrive provider scaffolding

## Features

- Native macOS SwiftUI app with a main window and menu bar extra.
- Dock window can be closed while the menu bar app keeps running.
- Task groups/projects, including a default `General` group.
- Tasks with title, optional description, optional due date, optional link, status, and priority.
- Statuses: `To Do`, `In Progress`, `Completed`, and `Blocked`.
- Priorities: `Low`, `Normal`, and `High`.
- High-priority tasks are sorted to the top and highlighted with an exclamation mark.
- Expandable/collapsible group sections with per-group colors.
- Completed tasks are hidden in the main window by default, with a View menu toggle to show them when needed.
- Menu bar quick-add flow for tasks and groups.
- Opening the full main window from the menu bar dismisses the menu bar window for a cleaner view switch.
- Optional blurred/faded background images for the main window and menu bar window.
- Configurable app font, defaulting to SF Mono.
- Optional launch at login.
- Daily 9:00 AM notifications for high-priority tasks and tasks due today.
- Local JSON persistence in Application Support.
- Unit tests covering models, storage, and task-store behavior.

## Project Status

This is an alpha macOS app. Version `0.5` is intended for early testers who are comfortable with a local-first productivity app that may still change shape.

Local task management is functional. Cloud sync is currently represented by provider scaffolding:

- iCloud/CloudKit provider placeholder.
- OneDrive personal/work provider placeholder.

Before treating sync as production-ready, the providers need real account/auth flows, merge behavior, conflict handling, and user-visible sync state.

For release prep and tester-facing notes, see:

- [Alpha tester guide](docs/ALPHA_TESTER_GUIDE.md)
- [Release checklist](docs/RELEASE_CHECKLIST.md)
- [0.5 alpha release notes](docs/RELEASE_NOTES_0.5_ALPHA.md)

## Requirements

- macOS 15.0 or later.
- Xcode with the macOS SDK.
- Swift 6.

## Getting Started

1. Clone the repository.
2. Open `ToDoListApp.xcodeproj` in Xcode.
3. Select the `ToDoListApp` target.
4. Set your development team for signing.
5. Confirm the bundle identifier is appropriate for your signing team.
6. Build and run the `ToDoListApp` scheme.

## Build From Terminal

```sh
xcodebuild \
  -project ToDoListApp.xcodeproj \
  -scheme ToDoListApp \
  -configuration Debug \
  -derivedDataPath /tmp/todo-derived \
  build
```

After building, the debug app bundle is usually available at:

```text
/tmp/todo-derived/Build/Products/Debug/To-Do List.app
```

## Create an Alpha Build

For the `0.5` alpha, use a signed Release build from Xcode when sharing with testers.

1. Open `ToDoListApp.xcodeproj`.
2. Select the `ToDoListApp` target.
3. Set your development team.
4. Confirm the marketing version is `0.5` and increment the build number if you are replacing a prior tester build.
5. Choose **Product > Archive**.
6. Export a signed Developer ID or development build appropriate for your tester group.
7. Share the app together with the [alpha tester guide](docs/ALPHA_TESTER_GUIDE.md).

For a very small trusted tester group, an unsigned zip can be shared through GitHub Releases. Expect macOS Gatekeeper friction for unsigned builds.

## Run Tests

```sh
xcodebuild test \
  -project ToDoListApp.xcodeproj \
  -scheme ToDoListApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64'
```

## Repository Layout

```text
ToDoListApp/
  Models/       Task, group, status, and priority models
  Settings/     App settings and appearance preferences
  Storage/      Local JSON persistence and task-store logic
  Sync/         Cloud sync provider interfaces and placeholders
  Views/        SwiftUI app, menu bar, settings, and task views

ToDoListAppTests/
  Unit tests for model coding, persistence, and store behavior
```

## Data Storage

Tasks are stored locally as JSON in the app's Application Support directory under `ToDoListApp/tasks.json`.

The app also includes a settings reset flow that requires two confirmations before deleting task/group data.

## GitHub CI

The included GitHub Actions workflow runs the unit test suite on macOS for pull requests and pushes to `main`.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE).
