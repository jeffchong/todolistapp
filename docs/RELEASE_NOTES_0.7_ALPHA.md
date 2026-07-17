# To-Do List 0.7 Alpha 1

Tag: `v0.7.0-alpha.1`
Marketing version: `0.7`
Build: `7`

Seventh alpha release for external testing.

## Highlights

- Native macOS SwiftUI app with main window and menu bar utility.
- Daily task notifications are now explicitly enabled from Settings instead of prompting automatically at launch.
- Testers can choose the time for notifications about open high-priority tasks and tasks due today.
- Settings shows the current macOS notification-permission status and guidance when access is denied.
- Menu bar task detail popovers let testers change task priority without opening the full task editor.
- Completed tasks are hidden in the main window by default and can be shown from the View menu.
- Local groups and tasks include status, priority, due date, description, and link fields.
- Optional app font, background image, launch-at-login, reset, and daily reminder settings.
- Visible version/build labels in the main window and menu bar for easier feedback.

## Known Limitations

- The menu bar app must be running at the selected reminder time.
- Cloud sync is not active yet.
- Data is local to the current Mac.
- Import/export is not implemented yet.
- This alpha is ad-hoc signed but not notarized. Testers may need to right-click/control-click **Open** the first time after verifying the release source.

## Suggested Tester Pass

- Launch a fresh install and confirm macOS does not request notification permission automatically.
- Open Settings, enable **Daily task notifications**, and allow the macOS permission request.
- Choose a reminder time a few minutes ahead.
- Create several open high-priority tasks and a task due today, then leave the menu bar app running.
- Confirm one notification appears for each eligible task at the selected time.
- Disable daily task notifications and confirm later reminders stop.
- Create, edit, complete, and reset tasks as in prior alpha passes.

## Tester Feedback

Please include the macOS version, app version/build shown in the app, expected behavior, actual behavior, and steps to reproduce. Screenshots or screen recordings are useful for visual and interaction issues.
