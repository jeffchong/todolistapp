import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    @State private var showingNewTask = false
    @State private var showingNewGroup = false
    @State private var newGroupName = ""
    @State private var draggedGroupID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                BackgroundImageView(isEnabled: settings.showMainWindowBackground && settings.hasBackgroundImage)
                    .environmentObject(settings)

                VStack(spacing: 0) {
                    header

                    if store.groups.isEmpty {
                        emptyState
                    } else {
                        taskList
                    }

                    footer
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

    private var footer: some View {
        HStack {
            Spacer()

            Text(AppVersionDisplay.versionAndBuild)
                .font(settings.appFont(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .help("App version \(AppVersionDisplay.versionAndBuild)")
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: 18, pinnedViews: [.sectionHeaders]) {
                ForEach(store.groups) { group in
                    GroupSectionView(
                        group: group,
                        showsReorderHandle: store.canReorderGroup(group),
                        reservesReorderHandleSpace: store.groups.count > 1,
                        onDragGroup: store.canReorderGroup(group) ? {
                            draggedGroupID = group.id
                            return NSItemProvider(object: group.id.uuidString as NSString)
                        } : nil
                    )
                        .environmentObject(settings)
                        .environmentObject(store)
                        .opacity(draggedGroupID == group.id ? 0.65 : 1)
                        .onDrop(
                            of: [UTType.plainText],
                            delegate: GroupReorderDropDelegate(
                                targetGroupID: group.id,
                                store: store,
                                draggedGroupID: $draggedGroupID
                            )
                        )
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

private struct GroupReorderDropDelegate: DropDelegate {
    let targetGroupID: UUID
    let store: TaskStore
    @Binding var draggedGroupID: UUID?

    func dropEntered(info: DropInfo) {
        guard let draggedGroupID, draggedGroupID != targetGroupID else { return }
        guard let sourceIndex = store.groups.firstIndex(where: { $0.id == draggedGroupID }) else { return }
        guard let targetIndex = store.groups.firstIndex(where: { $0.id == targetGroupID }) else { return }

        let destination = sourceIndex < targetIndex ? targetIndex + 1 : targetIndex
        withAnimation(.snappy(duration: 0.18)) {
            store.moveGroup(id: draggedGroupID, to: destination)
        }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedGroupID = nil
        return true
    }

    func dropExited(info: DropInfo) {
        guard !info.hasItemsConforming(to: [UTType.plainText]) else { return }
        draggedGroupID = nil
    }
}
