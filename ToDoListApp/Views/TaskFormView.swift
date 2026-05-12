import SwiftUI

struct TaskFormView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var store: TaskStore
    @Environment(\.dismiss) private var dismiss

    private let existingTask: TaskItem?
    private let presetGroupID: UUID?

    @State private var title: String
    @State private var notes: String
    @State private var groupID: UUID
    @State private var status: TaskStatus
    @State private var priority: TaskPriority
    @State private var hasDueDate: Bool
    @State private var dueDate: Date
    @State private var linkText: String
    @State private var showingDeleteConfirmation = false

    init(existingTask: TaskItem? = nil, presetGroupID: UUID? = nil) {
        self.existingTask = existingTask
        self.presetGroupID = presetGroupID
        _title = State(initialValue: existingTask?.title ?? "")
        _notes = State(initialValue: existingTask?.notes ?? "")
        _groupID = State(initialValue: existingTask?.groupID ?? presetGroupID ?? UUID())
        _status = State(initialValue: existingTask?.status ?? .todo)
        _priority = State(initialValue: existingTask?.priority ?? .normal)
        _hasDueDate = State(initialValue: existingTask?.dueDate != nil)
        _dueDate = State(initialValue: existingTask?.dueDate ?? .now)
        _linkText = State(initialValue: existingTask?.link?.absoluteString ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Task") {
                    TextField("Title", text: $title)

                    Picker("Group", selection: $groupID) {
                        ForEach(store.groups) { group in
                            Text(group.name).tag(group.id)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases) { status in
                            Label(status.rawValue, systemImage: status.systemImage)
                                .tag(status)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases) { priority in
                            Label(priority.rawValue, systemImage: priority.systemImage)
                                .tag(priority)
                        }
                    }
                }

                Section("Details") {
                    Toggle("Due date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Date", selection: $dueDate, displayedComponents: .date)
                    }

                    TextField("Link", text: $linkText)

                    VStack(alignment: .leading) {
                        Text("Description")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 150)
                            .scrollContentBackground(.hidden)
                            .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                if existingTask != nil {
                    Button("Delete", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                }

                Spacer()

                Button("Cancel", role: .cancel) {
                    dismiss()
                }

                Button(existingTask == nil ? "Create" : "Save") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .font(settings.appFont(size: 13))
        .onAppear {
            if existingTask == nil, !store.groups.contains(where: { $0.id == groupID }) {
                groupID = presetGroupID ?? store.defaultGroupID
            }
        }
        .confirmationDialog("Delete this task?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let existingTask {
                    store.deleteTask(existingTask)
                }
                dismiss()
            }
        }
    }

    private func save() {
        let url = sanitizedURL(from: linkText)

        if var existingTask {
            existingTask.title = title
            existingTask.notes = notes
            existingTask.groupID = groupID
            existingTask.status = status
            existingTask.priority = priority
            existingTask.dueDate = hasDueDate ? dueDate : nil
            existingTask.link = url
            store.updateTask(existingTask)
        } else {
            store.addTask(
                title: title,
                notes: notes,
                groupID: groupID,
                dueDate: hasDueDate ? dueDate : nil,
                link: url,
                status: status,
                priority: priority
            )
        }

        dismiss()
    }

    private func sanitizedURL(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }
}
