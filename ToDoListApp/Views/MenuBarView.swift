import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    @AppStorage("collapsedMenuBarGroupIDs") private var collapsedMenuBarGroupIDs = ""
    @State private var quickTitle = ""
    @State private var isCreatingGroup = false
    @State private var newGroupName = ""
    @State private var selectedGroupID: UUID?
    @State private var detailTask: TaskItem?

    var body: some View {
        ZStack {
            BackgroundImageView(isEnabled: settings.showMenuBarBackground && settings.hasBackgroundImage)
                .environmentObject(settings)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 22, height: 22)
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    Text("To-Do List")
                        .font(settings.appFont(size: 13, weight: .semibold))

                    Spacer()

                    Button {
                        AppWindowLifecycle.prepareToShowMainWindow()
                        openWindow(id: "main")
                        dismiss()
                    } label: {
                        Label("Open", systemImage: "macwindow")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Open app window")
                }

                HStack {
                    TextField("New task", text: $quickTitle)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(addQuickTask)

                    Button {
                        addQuickTask()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    .labelStyle(.iconOnly)
                    .disabled(quickTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                HStack(spacing: 8) {
                    Picker("Group", selection: selectedGroupBinding) {
                        ForEach(store.groups) { group in
                            Text(group.name).tag(Optional(group.id))
                        }
                    }

                    Button {
                        withAnimation(.snappy(duration: 0.16)) {
                            isCreatingGroup.toggle()
                        }
                    } label: {
                        Label("New Group", systemImage: "folder.badge.plus")
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Create a new group")
                }

                if isCreatingGroup {
                    HStack(spacing: 8) {
                        TextField("New group", text: $newGroupName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit(addGroup)

                        Button {
                            addGroup()
                        } label: {
                            Label("Create group", systemImage: "checkmark")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .disabled(newGroupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .help("Create group")

                        Button {
                            cancelGroupCreation()
                        } label: {
                            Label("Cancel", systemImage: "xmark")
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help("Cancel")
                    }
                }

                Divider()

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        if store.groups.isEmpty {
                            Text("No groups")
                                .font(settings.appFont(size: 11))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 18)
                        } else {
                            ForEach(store.groups) { group in
                                menuGroupSection(group)
                            }

                            if shouldShowScrollHint {
                                Text("\(store.groups.count) groups")
                                    .font(settings.appFont(size: 10))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 2)
                            }
                        }
                    }
                    .padding(.vertical, 1)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .scrollContentBackground(.hidden)
                .frame(height: taskListHeight, alignment: .top)

                Divider()

                HStack {
                    Button {
                        AppWindowLifecycle.prepareToShowMainWindow()
                        openSettings()
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .labelStyle(.iconOnly)
                    .help("Settings")

                    Spacer()

                    HStack(spacing: 12) {
                        Label("\(store.openTasks.count)", systemImage: "checklist.unchecked")
                            .font(settings.appFont(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .help("\(store.openTasks.count) open tasks")

                        Text(AppVersionDisplay.versionAndBuild)
                            .font(settings.appFont(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .help("App version \(AppVersionDisplay.versionAndBuild)")

                        Image(systemName: cloudSyncStatus.systemImage)
                            .font(settings.appFont(size: 12, weight: .semibold))
                            .foregroundStyle(cloudSyncStatus.color)
                            .help(cloudSyncStatus.helpText)
                    }
                    .frame(minWidth: 132)

                    Spacer()

                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Label("Quit", systemImage: "power")
                    }
                    .labelStyle(.iconOnly)
                    .help("Quit")
                }
            }
            .padding(14)
        }
        .frame(width: 380)
        .frame(maxHeight: menuMaxHeight)
        .font(settings.appFont(size: 13))
        .onAppear {
            selectedGroupID = selectedGroupID ?? store.defaultGroupID
        }
    }

    private var menuMaxHeight: CGFloat {
        guard let height = NSScreen.main?.visibleFrame.height else {
            return 440
        }
        return height * 0.5
    }

    private var taskListMaxHeight: CGFloat {
        max(120, menuMaxHeight - (isCreatingGroup ? 228 : 188))
    }

    private var taskListHeight: CGFloat {
        let headerHeight = CGFloat(max(store.groups.count, 1)) * 40
        let taskHeight = CGFloat(store.openTasks.count) * 40
        let emptyGroupTextHeight = CGFloat(store.groupsWithoutOpenTasksCount) * 26
        return min(taskListMaxHeight, max(96, headerHeight + taskHeight + emptyGroupTextHeight))
    }

    private var shouldShowScrollHint: Bool {
        taskListEstimatedContentHeight > taskListMaxHeight
    }

    private var taskListEstimatedContentHeight: CGFloat {
        let headerHeight = CGFloat(max(store.groups.count, 1)) * 40
        let taskHeight = CGFloat(store.openTasks.count) * 40
        let emptyGroupTextHeight = CGFloat(store.groupsWithoutOpenTasksCount) * 26
        return headerHeight + taskHeight + emptyGroupTextHeight
    }

    private var selectedGroupBinding: Binding<UUID?> {
        Binding(
            get: { selectedGroupID ?? store.defaultGroupID },
            set: { selectedGroupID = $0 }
        )
    }

    private var cloudSyncStatus: CloudSyncDisplayStatus {
        .notConfigured
    }

    private var collapsedGroupIDs: Set<UUID> {
        Set(
            collapsedMenuBarGroupIDs
                .split(separator: ",")
                .compactMap { UUID(uuidString: String($0)) }
        )
    }

    private func menuGroupSection(_ group: TaskGroup) -> some View {
        let openTasks = store.openTasks(for: group)
        let isCollapsed = collapsedGroupIDs.contains(group.id)

        return VStack(alignment: .leading, spacing: 6) {
            Button {
                toggleMenuGroup(group)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isCollapsed ? "chevron.right" : "chevron.down")
                        .font(settings.appFont(size: 10, weight: .semibold))
                        .frame(width: 14)

                    Text(group.name)
                        .font(settings.appFont(size: 12, weight: .semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(openTasks.isEmpty ? "0" : "\(openTasks.count)")
                        .font(settings.appFont(size: 10, weight: .semibold))
                        .foregroundStyle(.primary.opacity(0.82))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.white.opacity(0.22), in: Capsule())
                }
                .foregroundStyle(.primary)
                .padding(.horizontal, 9)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: group.colorHex).opacity(0.68))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: group.colorHex).opacity(0.9), lineWidth: 1)
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .help(isCollapsed ? "Show open tasks" : "Hide open tasks")

            if !isCollapsed {
                if openTasks.isEmpty {
                    Text("No open tasks")
                        .font(settings.appFont(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 24)
                        .padding(.vertical, 4)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(openTasks) { task in
                            menuTaskRow(task)
                        }
                    }
                    .padding(.leading, 10)
                }
            }
        }
    }

    private func menuTaskRow(_ task: TaskItem) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Menu {
                ForEach(TaskStatus.allCases) { status in
                    Button {
                        store.updateStatus(for: task, to: status)
                    } label: {
                        Label(status.rawValue, systemImage: status.systemImage)
                    }
                }
            } label: {
                Image(systemName: task.status.systemImage)
                    .foregroundStyle(task.status.color)
                    .frame(width: 20)
            }
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .help("Change status")

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    if task.priority == .high {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .help("High priority")
                    }

                    Text(task.title)
                        .font(settings.appFont(size: 12, weight: .medium))
                        .lineLimit(2)
                }
            }

            Spacer()

            if let dueDate = task.dueDate {
                Text(dueDate.formatted(date: .numeric, time: .omitted))
                    .font(.caption)
                    .font(settings.appFont(size: 11))
                    .foregroundStyle(.secondary)
            }

            Button {
                detailTask = task
            } label: {
                Label("Details", systemImage: "info.circle")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("View task details")
            .popover(
                isPresented: Binding(
                    get: { detailTask?.id == task.id },
                    set: { isPresented in
                        if !isPresented {
                            detailTask = nil
                        }
                    }
                ),
                arrowEdge: .trailing
            ) {
                MenuBarTaskDetailsView(task: detailTask ?? task)
                    .environmentObject(settings)
                    .environmentObject(store)
            }
        }
        .padding(8)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }

    private func toggleMenuGroup(_ group: TaskGroup) {
        var ids = collapsedGroupIDs
        if ids.contains(group.id) {
            ids.remove(group.id)
        } else {
            ids.insert(group.id)
        }
        collapsedMenuBarGroupIDs = ids.map(\.uuidString).sorted().joined(separator: ",")
    }

    private func addQuickTask() {
        let title = quickTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        store.addTask(
            title: title,
            notes: "",
            groupID: selectedGroupID ?? store.defaultGroupID,
            dueDate: nil,
            link: nil
        )
        quickTitle = ""
    }

    private func addGroup() {
        let name = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let group = store.addGroup(named: name)
        selectedGroupID = group.id
        newGroupName = ""
        withAnimation(.snappy(duration: 0.16)) {
            isCreatingGroup = false
        }
    }

    private func cancelGroupCreation() {
        newGroupName = ""
        withAnimation(.snappy(duration: 0.16)) {
            isCreatingGroup = false
        }
    }
}

private struct MenuBarTaskDetailsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    let task: TaskItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: task.status.systemImage)
                    .foregroundStyle(task.status.color)
                    .frame(width: 18)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(settings.appFont(size: 13, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(store.groupName(for: task.groupID))
                        .font(settings.appFont(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                detailRow("Status", systemImage: task.status.systemImage, value: task.status.rawValue)
                detailRow("Priority", systemImage: task.priority.systemImage, value: task.priority.rawValue)

                if let dueDate = task.dueDate {
                    detailRow(
                        "Due",
                        systemImage: "calendar",
                        value: dueDate.formatted(date: .abbreviated, time: .omitted)
                    )
                }
            }

            if !task.notes.isEmpty {
                Divider()

                Text(task.notes)
                    .font(settings.appFont(size: 12))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            } else if task.dueDate == nil && task.link == nil {
                Text("No additional details")
                    .font(settings.appFont(size: 12))
                    .foregroundStyle(.secondary)
            }

            if let link = task.link {
                Divider()

                Link(destination: link) {
                    Label(link.host(percentEncoded: false) ?? "Open Link", systemImage: "link")
                        .font(settings.appFont(size: 12, weight: .medium))
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
        .frame(width: 300, alignment: .leading)
    }

    private func detailRow(_ label: String, systemImage: String, value: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(settings.appFont(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)

            Text(value)
                .font(settings.appFont(size: 12))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

private enum CloudSyncDisplayStatus {
    case synced
    case syncing
    case notConfigured

    var systemImage: String {
        switch self {
        case .synced:
            "checkmark.icloud"
        case .syncing:
            "arrow.triangle.2.circlepath.icloud"
        case .notConfigured:
            "icloud.slash"
        }
    }

    var color: Color {
        switch self {
        case .synced:
            .green
        case .syncing:
            .blue
        case .notConfigured:
            .secondary
        }
    }

    var helpText: String {
        switch self {
        case .synced:
            "Cloud sync is up to date"
        case .syncing:
            "Cloud sync is in progress or needs updating"
        case .notConfigured:
            "Cloud sync is not set up"
        }
    }
}
