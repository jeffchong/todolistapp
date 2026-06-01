import SwiftUI

@main
struct ToDoListApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = AppSettings()
    @StateObject private var store = TaskStore()

    var body: some Scene {
        Window("To-Do List", id: "main") {
            ContentView()
                .environmentObject(settings)
                .environmentObject(store)
                .frame(minWidth: 760, minHeight: 540)
        }
        .defaultSize(width: 860, height: 620)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .showNewTaskSheet, object: nil)
                }
                .keyboardShortcut("n")
            }

            CommandGroup(replacing: .appTermination) {
                Button("Close to Menu Bar") {
                    AppWindowLifecycle.closeMainWindowToMenuBar()
                }
                .keyboardShortcut("q")
            }

            CommandGroup(after: .toolbar) {
                Toggle("Show Completed Items", isOn: $settings.showCompletedTasksInMainWindow)
            }
        }

        MenuBarExtra("To-Do List", systemImage: "checklist") {
            MenuBarView()
                .environmentObject(settings)
                .environmentObject(store)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(settings)
                .environmentObject(store)
                .frame(width: 460)
        }
    }
}

extension Notification.Name {
    static let showNewTaskSheet = Notification.Name("showNewTaskSheet")
}

enum AppVersionDisplay {
    static var shortVersion: String {
        formatVersion(version)
    }

    static var versionAndBuild: String {
        "\(shortVersion) (\(build))"
    }

    private static var version: String {
        let bundleVersion = Bundle.main
            .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String

        guard let bundleVersion, !bundleVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "0.5"
        }

        return bundleVersion
    }

    private static var build: String {
        let bundleBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        guard let bundleBuild, !bundleBuild.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "5"
        }

        return bundleBuild
    }

    private static func formatVersion(_ version: String) -> String {
        return version.hasPrefix("v") ? version : "v\(version)"
    }
}
