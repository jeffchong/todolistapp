# Release Checklist

Use this checklist when preparing a `0.6` alpha build for testers.

## Version

- Confirm `MARKETING_VERSION` is `0.6`.
- Confirm the app bundle identifier is `com.jeffchong.todolist`.
- Confirm `CURRENT_PROJECT_VERSION` is `6`, or increment it if you are replacing a prior `0.6` tester build.
- Add release notes to `CHANGELOG.md`.
- Confirm README status and tester docs match the release.
- Confirm `docs/RELEASE_NOTES_0.6_ALPHA.md` matches the GitHub Release draft.

## Validation

- Run unit tests:

```sh
xcodebuild test \
  -project ToDoListApp.xcodeproj \
  -scheme ToDoListApp \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64'
```

- Run the Swift package tests:

```sh
swift test -Xswiftc -warnings-as-errors
```

- Build the app in Release for local validation:

```sh
xcodebuild build \
  -project ToDoListApp.xcodeproj \
  -scheme ToDoListApp \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /tmp/todo-release-derived \
  CODE_SIGNING_ALLOWED=NO
```

## Manual Smoke Test

- Launch the app and create a task.
- Create a group and move/create a task in that group.
- Rename a custom group, change its color, and delete it.
- Edit task title, description, due date, link, status, and priority.
- Confirm high-priority tasks sort above normal tasks.
- Complete a task and confirm it is hidden by default in the main window.
- Toggle **View > Show Completed Items** and confirm completed tasks appear and hide again.
- Close the main window and open it again from the menu bar.
- Open the full window from the menu bar and confirm the menu bar window dismisses.
- Add a task from the menu bar.
- Change a task status from the menu bar.
- Change a task priority from the menu bar task detail popover.
- Open settings.
- Toggle launch at login and confirm any macOS approval prompt or status.
- Select and clear a background image.
- Reset task data and confirm the app returns to an empty `General` group.
- Quit and relaunch to confirm data persists.

## Packaging

- Archive from Xcode using the `ToDoListApp` scheme.
- Export a signed build appropriate for the tester group.
- Use Developer ID signing and notarization for testers outside your development team when available.
- Zip the exported `To-Do List.app`.
- Attach or link the alpha tester guide with the build.
- Keep a copy of the exact zip that was shared.

For a small trusted-tester alpha, an unsigned Release build can be zipped locally and attached to GitHub Releases. This is acceptable for a tiny known group, but it will create Gatekeeper friction and is not a good long-term distribution path.

## GitHub Release Draft

Suggested title:

```text
To-Do List 0.6 Alpha 1
```

Suggested tag:

```text
v0.6.0-alpha.1
```

Suggested release notes:

```text
Sixth alpha release for external testing.

Highlights:
- Native macOS SwiftUI app with main window and menu bar utility.
- Local groups and tasks with status, priority, due date, description, and link fields.
- Menu bar quick-add and status updates.
- Menu bar task detail popovers now support priority changes.
- Optional app font, background image, launch-at-login, reset, and daily reminder settings.
- Visible version/build labels in the main window and menu bar for easier feedback.
- Drag-and-drop custom group reordering with `General` pinned at the top.
- Menu bar task detail popovers for status, priority, due date, notes, and links.
- Main-window group options for renaming groups, changing colors, and deleting custom groups.
- Menu bar settings button opens Settings reliably.
- Completed tasks are hidden in the main window by default, with a View menu toggle to show or hide them.
- Opening the full main window from the menu bar dismisses the menu bar window.

Known limitations:
- Cloud sync is not active yet.
- Data is local to the current Mac.
- Import/export is not implemented yet.
```
