import SwiftUI

struct TaskRowView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    let task: TaskItem

    @State private var showingDetails = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            statusMenu

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    if task.priority == .high {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.red)
                            .help("High priority")
                    }

                    Text(task.title)
                        .font(settings.appFont(size: 13, weight: .semibold))
                        .strikethrough(task.status == .completed)
                        .foregroundStyle(task.status == .completed ? .secondary : .primary)
                }

                if !task.notes.isEmpty {
                    Text(task.notes)
                        .font(.callout)
                        .font(settings.appFont(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                metadata
            }

            Spacer(minLength: 8)

            Button {
                showingDetails = true
            } label: {
                Label("Details", systemImage: "info.circle")
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .help("Details")
        }
        .padding(12)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .sheet(isPresented: $showingDetails) {
            TaskFormView(existingTask: task)
                .environmentObject(settings)
                .environmentObject(store)
                .frame(minWidth: 500, minHeight: 560)
        }
    }

    private var statusMenu: some View {
        Menu {
            ForEach(TaskStatus.allCases) { status in
                Button {
                    store.updateStatus(for: task, to: status)
                } label: {
                    Label(status.rawValue, systemImage: status.systemImage)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: task.status.systemImage)
                Text(task.status.rawValue)
            }
            .foregroundStyle(task.status.color)
            .frame(minWidth: 112, alignment: .leading)
        }
        .menuStyle(.button)
        .buttonStyle(.bordered)
        .controlSize(.small)
        .fixedSize()
    }

    private var metadata: some View {
        HStack(spacing: 12) {
            if let dueDate = task.dueDate {
                Label(dueDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
            }

            if let link = task.link {
                Link(destination: link) {
                    Label("Link", systemImage: "link")
                }
            }
        }
        .font(.caption)
        .font(settings.appFont(size: 11))
        .foregroundStyle(.secondary)
    }
}
