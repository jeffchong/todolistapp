import SwiftUI

struct GroupSectionView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    let group: TaskGroup

    @State private var showingNewTask = false

    var body: some View {
        Section {
            let tasks = store.tasks(for: group)
            if group.isCollapsed {
                EmptyView()
            } else if tasks.isEmpty {
                HStack {
                    Text("No tasks")
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

            ColorPicker(
                "Group color",
                selection: Binding(
                    get: { Color(hex: group.colorHex) },
                    set: { store.updateGroupColor(group, colorHex: $0.hexString) }
                ),
                supportsOpacity: false
            )
            .labelsHidden()
            .controlSize(.small)
            .frame(width: 28)
            .help("Group color")

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
