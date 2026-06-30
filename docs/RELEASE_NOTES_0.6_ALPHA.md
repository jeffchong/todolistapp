# To-Do List 0.6 Alpha 1

Tag: `v0.6.0-alpha.1`
Marketing version: `0.6`
Build: `6`

Sixth alpha release for external testing.

## Highlights

- Native macOS SwiftUI app with main window and menu bar utility.
- Menu bar task detail popovers now let testers change task priority without opening the full task editor.
- Completed tasks are hidden in the main window by default.
- **View > Show Completed Items** shows or hides completed tasks in the main window.
- Opening the full main window from the menu bar dismisses the menu bar window so the interaction feels like switching views.
- Main-window group options popover for renaming groups, changing colors, and deleting custom groups.
- Drag-and-drop custom group reordering in the main window.
- Local groups and tasks with status, priority, due date, description, and link fields.
- Optional app font, background image, launch-at-login, reset, and daily reminder settings.
- Visible version/build labels in the main window and menu bar for easier feedback.

## Known Limitations

- Cloud sync is not active yet.
- Data is local to the current Mac.
- Import/export is not implemented yet.
- This alpha is ad-hoc signed but not notarized. Testers may need to right-click/control-click **Open** the first time after verifying the release source.

## Suggested Tester Pass

- Add a task from the menu bar, open its task detail popover, and change the priority.
- Confirm high-priority tasks sort above normal tasks after changing priority from the menu bar.
- Complete a task and confirm it is hidden by default in the main window.
- Toggle **View > Show Completed Items** and confirm completed tasks appear and hide again.
- Open the full main window from the menu bar and confirm the menu bar window dismisses.
- Rename a custom group, change its color, and delete a custom group from the main window group options popover.
- Reorder custom groups in the main window, quit, and relaunch to confirm the order persists.
- Create, edit, complete, and reset tasks as in prior alpha passes.

## Tester Feedback

Please include the macOS version, app version/build shown in the app, expected behavior, actual behavior, and steps to reproduce. Screenshots or screen recordings are useful for visual and interaction issues.
