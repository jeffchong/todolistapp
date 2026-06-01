import SwiftUI

struct GroupSectionView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    let group: TaskGroup
    var showsReorderHandle = false
    var reservesReorderHandleSpace = false
    var onDragGroup: (() -> NSItemProvider)?

    @State private var showingNewTask = false
    @State private var showingGroupOptions = false

    var body: some View {
        Section {
            let tasks = settings.showCompletedTasksInMainWindow ? store.tasks(for: group) : store.openTasks(for: group)
            if group.isCollapsed {
                EmptyView()
            } else if tasks.isEmpty {
                HStack {
                    Text(settings.showCompletedTasksInMainWindow ? "No tasks" : "No open tasks")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(14)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks) { task in
                        TaskRowView(task: task)
                            .environmentObject(settings)
                            .environmentObject(store)
                    }
                }
            }
        } header: {
            groupHeader
        }
        .sheet(isPresented: $showingNewTask) {
            TaskFormView(presetGroupID: group.id)
                .environmentObject(settings)
                .environmentObject(store)
                .frame(minWidth: 500, minHeight: 520)
        }
    }

    private var groupHeader: some View {
        let barColor = Color(hex: group.colorHex)
        let openCount = store.taskCount(for: group, includeCompleted: false)

        return HStack(spacing: 10) {
            if showsReorderHandle, let onDragGroup {
                Image(systemName: "line.3.horizontal")
                    .font(settings.appFont(size: 12, weight: .semibold))
                    .foregroundStyle(.primary.opacity(0.72))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
                    .onDrag(onDragGroup)
                    .help("Drag to reorder group")
            } else if reservesReorderHandleSpace {
                Color.clear
                    .frame(width: 18, height: 18)
            }

            Button {
                store.toggleGroupCollapsed(group)
            } label: {
                Image(systemName: group.isCollapsed ? "chevron.right" : "chevron.down")
                    .font(settings.appFont(size: 11, weight: .semibold))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.borderless)
            .help(group.isCollapsed ? "Expand group" : "Collapse group")

            Text(group.name)
                .font(settings.appFont(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            Text(group.isCollapsed ? "\(openCount) open" : "\(openCount)")
                .font(settings.appFont(size: 11, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.82))
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(.white.opacity(0.22), in: Capsule())

            Spacer()

            Button {
                showingGroupOptions = true
            } label: {
                Label("Group Options", systemImage: "ellipsis.circle")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Group options")
            .popover(isPresented: $showingGroupOptions, arrowEdge: .bottom) {
                GroupOptionsView(group: group)
                    .environmentObject(settings)
                    .environmentObject(store)
            }

            Button {
                showingNewTask = true
            } label: {
                Label("Add Task", systemImage: "plus")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Add task")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(barColor.opacity(0.72))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(barColor.opacity(0.95), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(count: 2) {
            store.toggleGroupCollapsed(group)
        }
    }
}

private struct GroupOptionsView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    let group: TaskGroup

    @State private var groupName: String
    @State private var showingDeleteConfirmation = false

    init(group: TaskGroup) {
        self.group = group
        _groupName = State(initialValue: group.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Group Options")
                .font(settings.appFont(size: 14, weight: .semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(settings.appFont(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    TextField("Group name", text: $groupName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit(saveName)

                    Button("Rename") {
                        saveName()
                    }
                    .disabled(!canSaveName)
                }
            }

            ColorPicker(
                "Color",
                selection: Binding(
                    get: { Color(hex: group.colorHex) },
                    set: { store.updateGroupColor(group, colorHex: $0.hexString) }
                ),
                supportsOpacity: false
            )

            Divider()

            Button("Delete Group...", role: .destructive) {
                showingDeleteConfirmation = true
            }
            .disabled(!store.canDeleteGroup(group))
            .help(store.canDeleteGroup(group) ? "Delete this group" : "The General group cannot be deleted")
        }
        .padding(16)
        .frame(width: 280, alignment: .leading)
        .font(settings.appFont(size: 13))
        .onChange(of: group.name) { _, newName in
            groupName = newName
        }
        .alert("Delete \(group.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Group", role: .destructive) {
                store.deleteGroup(group)
                dismiss()
            }
        } message: {
            Text("Tasks in this group will move to General.")
        }
    }

    private var canSaveName: Bool {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName != group.name
    }

    private func saveName() {
        guard canSaveName else { return }
        store.renameGroup(group, to: groupName)
    }
}
