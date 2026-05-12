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
