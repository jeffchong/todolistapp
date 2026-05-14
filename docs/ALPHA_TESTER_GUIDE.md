# To-Do List 0.2 Alpha Tester Guide

Thanks for trying the To-Do List alpha. This `0.2` build is meant to validate the core local task workflow before cloud sync and broader distribution are finished.

## What to Expect

- Native macOS app with both a standard window and a menu bar utility.
- App version/build shown in the main window and menu bar to make feedback easier to match to a build.
- Local task and group management.
- Optional due dates, links, descriptions, statuses, and priorities.
- Daily 9:00 AM notifications for high-priority tasks and tasks due today.
- Local JSON persistence in Application Support.

## Alpha Limitations

- Cloud sync is not active yet. The iCloud and OneDrive areas are placeholders.
- Task data is stored only on the Mac where you run the app.
- There is no import/export flow yet.
- The app is not App Store distributed.
- Visual polish, accessibility, and edge cases are still being refined.

## Install

1. Download the shared `To-Do List.app` build.
2. Move it to your `Applications` folder.
3. Open it from Finder.
4. If macOS warns that the app is from an unidentified developer, confirm the build came from the expected GitHub release before bypassing Gatekeeper.
5. Allow notifications if you want daily reminders.

## Suggested Test Pass

Please try these workflows and note anything confusing, broken, or slower than expected:

- Create a few groups/projects.
- Create tasks with and without due dates.
- Add high-priority tasks and confirm they sort above normal tasks.
- Change task statuses from both the main window and menu bar.
- Add a link to a task and confirm it opens.
- Close the main window and keep using the menu bar app.
- Open settings and try font selection, launch at login, and background image settings.
- Reset task data from settings if you want to start over.
- Leave the app running across a restart or overnight and confirm data is still present.

## Feedback to Send

For each issue, include:

- macOS version.
- App version and build number shown in the app, such as `v0.2 (2)`.
- What you expected to happen.
- What actually happened.
- Steps to reproduce.
- Screenshot or screen recording if useful.

Feature feedback is also welcome. The most useful notes describe the task you were trying to complete, not only the exact button or screen you wanted.

## Data and Privacy

Task data is stored locally at:

```text
~/Library/Application Support/ToDoListApp/tasks.json
```

Background images selected in settings are copied into the same Application Support folder. The alpha build does not send task data to a remote service.

## Reset or Uninstall

To reset tasks and groups while keeping app settings, use **Settings > Data > Reset Task Data...**.

To remove local app data completely, quit the app and delete:

```text
~/Library/Application Support/ToDoListApp
```
