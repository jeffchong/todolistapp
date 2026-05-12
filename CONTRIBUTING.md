# Contributing

Thanks for helping improve To-Do List.

## Development Setup

1. Install Xcode.
2. Open `ToDoListApp.xcodeproj`.
3. Set a local signing team and bundle identifier.
4. Build and run the `ToDoListApp` scheme.

## Before Opening a Pull Request

- Keep changes focused and easy to review.
- Add or update tests for behavior changes.
- Run the unit tests:

```sh
xcodebuild test \
  -project ToDoListApp.xcodeproj \
  -scheme ToDoListApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64'
```

- Update `README.md` or `CHANGELOG.md` when user-facing behavior changes.

## Code Style

- Prefer existing SwiftUI and store patterns already used in the app.
- Keep UI state close to the view that owns it.
- Keep persistence and sorting behavior inside `TaskStore` unless there is a strong reason to split it out.
- Avoid adding dependencies until the app clearly needs them.

## Cloud Sync Work

Cloud sync should be treated carefully. Pull requests in this area should describe:

- The provider being changed.
- Authentication/account behavior.
- Conflict and merge behavior.
- How failed sync states are surfaced in the UI.
- Any migration impact on existing local JSON data.
