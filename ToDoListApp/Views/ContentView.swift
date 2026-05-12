import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    @State private var showingNewTask = false
    @State private var showingNewGroup = false
    @State private var newGroupName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundImageView(isEnabled: settings.showMainWindowBackground && settings.hasBackgroundImage)
                    .environmentObject(settings)

                VStack(spacing: 0) {
                    header

                    if store.tasks.isEmpty {
                        emptyState
                    } else {
                        taskList
                    }
                }
            }
            .navigationTitle("To-Do List")
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        showingNewGroup = true
                    } label: {
                        Label("New Group", systemImage: "folder.badge.plus")
                    }

                    Button {
                        showingNewTask = true
                    } label: {
                        Label("New Task", systemImage: "plus")
                    }
                    .keyboardShortcut("n")
                }
            }
            .sheet(isPresented: $showingNewTask) {
                TaskFormView()
                    .environmentObject(settings)
                    .environmentObject(store)
                    .frame(minWidth: 500, minHeight: 520)
            }
            .alert("New Group", isPresented: $showingNewGroup) {
                TextField("Group name", text: $newGroupName)
                Button("Cancel", role: .cancel) {
                    newGroupName = ""
                }
                Button("Create") {
                    store.addGroup(named: newGroupName)
                    newGroupName = ""
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .showNewTaskSheet)) { _ in
                showingNewTask = true
            }
            .font(settings.appFont(size: 13))
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Label("\(store.openTasks.count) open", systemImage: "tray.full")
                .foregroundStyle(.secondary)

            Spacer()

            if let error = store.lastError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                    .lineLimit(1)
                    .help(error)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.bar)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                ForEach(store.groups) { group in
                    GroupSectionView(group: group)
                        .environmentObject(settings)
                        .environmentObject(store)
                }
            }
            .padding(20)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checklist")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No tasks yet")
                .font(settings.appFont(size: 22, weight: .semibold))

            Button {
                showingNewTask = true
            } label: {
                Label("Create Task", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
