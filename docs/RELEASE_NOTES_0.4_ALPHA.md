# To-Do List 0.4 Alpha 1

Tag: `v0.4.0-alpha.1`
Marketing version: `0.4`
Build: `4`

Fourth alpha release for external testing.

## Highlights

- Native macOS SwiftUI app with main window and menu bar utility.
- Menu bar settings button now opens the Settings window reliably.
- Main-window group options popover for renaming groups, changing colors, and deleting custom groups.
- Deleting a custom group moves its tasks back into `General`; `General` remains protected from deletion.
- Drag-and-drop custom group reordering in the main window.
- Menu bar task detail popovers for status, priority, due date, notes, and links.
- Local groups and tasks with status, priority, due date, description, and link fields.
- Optional app font, background image, launch-at-login, reset, and daily reminder settings.
- Visible version/build labels in the main window and menu bar for easier feedback.

## Known Limitations

- Cloud sync is not active yet.
- Data is local to the current Mac.
- Import/export is not implemented yet.
- This alpha is ad-hoc signed but not notarized. Testers may need to right-click/control-click **Open** the first time after verifying the release source.

## Suggested Tester Pass

- Open Settings from the menu bar and confirm the Settings window appears.
- Rename a custom group, change its color, and delete a custom group from the main window group options popover.
- Confirm tasks from a deleted custom group move back into `General`.
- Reorder custom groups in the main window, quit, and relaunch to confirm the order persists.
- Create, edit, complete, and reset tasks as in prior alpha passes.

## Tester Feedback

Please include the macOS version, app version/build shown in the app, expected behavior, actual behavior, and steps to reproduce. Screenshots or screen recordings are useful for visual and interaction issues.
