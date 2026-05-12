# To-Do List

A native SwiftUI macOS to-do list app designed to live both as a standard dock/window app and as a menu bar utility.

The app is intentionally lightweight: tasks are grouped by project, can be managed quickly from the menu bar, and persist locally as JSON while cloud sync providers are being built out.

## Features

- Native macOS SwiftUI app with a main window and menu bar extra.
- Dock window can be closed while the menu bar app keeps running.
- Task groups/projects, including a default `General` group.
- Tasks with title, optional description, optional due date, optional link, status, and priority.
- Statuses: `To Do`, `In Progress`, `Completed`, and `Blocked`.
- Priorities: `Low`, `Normal`, and `High`.
- High-priority tasks are sorted to the top and highlighted with an exclamation mark.
- Expandable/collapsible group sections with per-group colors.
- Menu bar quick-add flow for tasks and groups.
- Optional blurred/faded background images for the main window and menu bar window.
- Configurable app font, defaulting to SF Mono.
- Optional launch at login.
- Daily 9:00 AM notifications for high-priority tasks and tasks due today.
- Local JSON persistence in Application Support.
- Unit tests covering models, storage, and task-store behavior.

## Project Status

This is an early macOS app. Local task management is functional. Cloud sync is currently represented by provider scaffolding:

- iCloud/CloudKit provider placeholder.
- OneDrive personal/work provider placeholder.

Before treating sync as production-ready, the providers need real account/auth flows, merge behavior, conflict handling, and user-visible sync state.

## Requirements

- macOS 15.0 or later.
- Xcode with the macOS SDK.
- Swift 6.

## Getting Started

1. Clone the repository.
2. Open `ToDoListApp.xcodeproj` in Xcode.
3. Select the `ToDoListApp` target.
4. Set your development team for signing.
5. Change the bundle identifier from `com.local.ToDoListApp` to one you own.
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
