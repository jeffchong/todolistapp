# Changelog

All notable changes to this project will be documented in this file.

This project follows a simple human-readable changelog format.

## Unreleased

- No unreleased changes yet.

## 0.3.0-alpha.1 - 2026-05-14

- Prepared the third alpha release for tester distribution.
- Bumped the app marketing version to `0.3` and build number to `3`.
- Added drag-and-drop custom group reordering in the main window while keeping `General` pinned at the top.
- Persisted manual group ordering across reloads and repaired older saved data where `General` was not first.
- Added menu bar task detail popovers for status, priority, due date, notes, and links.
- Added tests covering group reordering, order persistence, and legacy group-order repair.
- Refreshed release and tester documentation for the `0.3` alpha.

## 0.2.0-alpha.1 - 2026-05-14

- Prepared the second alpha release for tester distribution.
- Bumped the app marketing version to `0.2` and build number to `2`.
- Added visible app version/build labels in the main window and menu bar UI to make tester feedback easier to identify.
- Updated the main window empty-state behavior so existing groups remain visible even when all tasks are complete or removed.
- Refreshed release, security, and tester documentation for the `0.2` alpha.

## 0.1.0-alpha.1 - 2026-05-13

- Prepared the first alpha release for external testing.
- Added GitHub-ready project documentation and repository hygiene files.
- Added unit tests for core model, storage, and task-store behavior.
- Added task priority support with high-priority sorting and notifications.
- Added menu bar task/group management UI.
- Added app icon assets and menu bar title icon.
- Added settings for font selection, launch at login, backgrounds, and reset flow.
