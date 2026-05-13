import Foundation
import UserNotifications

@MainActor
final class TaskStore: ObservableObject {
    @Published private(set) var groups: [TaskGroup] = []
    @Published private(set) var tasks: [TaskItem] = []
    @Published var lastError: String?

    private let storage: TaskStorage
    private let reminderScheduler: TaskReminderScheduler?

    init(storage: TaskStorage = TaskStorage(), startsReminderScheduler: Bool = true) {
        self.storage = storage
        reminderScheduler = startsReminderScheduler ? TaskReminderScheduler() : nil
        load()
        reminderScheduler?.start(store: self)
    }

    var defaultGroupID: UUID {
        ensureDefaultGroup()
    }

    var openTasks: [TaskItem] {
        sorted(tasks.filter { $0.status != .completed })
    }

    var groupsWithoutOpenTasksCount: Int {
        groups.filter { openTasks(for: $0).isEmpty }.count
    }

    func tasks(for group: TaskGroup) -> [TaskItem] {
        sorted(tasks.filter { $0.groupID == group.id })
    }

    func openTasks(for group: TaskGroup) -> [TaskItem] {
        sorted(tasks.filter { $0.groupID == group.id && $0.status != .completed })
    }

    func taskCount(for group: TaskGroup, includeCompleted: Bool = true) -> Int {
        tasks.filter { task in
            task.groupID == group.id && (includeCompleted || task.status != .completed)
        }.count
    }

    func groupName(for groupID: UUID) -> String {
        groups.first(where: { $0.id == groupID })?.name ?? "General"
    }

    func reminderTasks(for date: Date = .now) -> [TaskItem] {
        sorted(
            tasks.filter { task in
                task.status != .completed && (task.priority == .high || isSameDay(task.dueDate, as: date))
            }
        )
    }

    @discardableResult
    func addGroup(named name: String) -> TaskGroup {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let group = TaskGroup(
            name: trimmedName.isEmpty ? "Untitled Group" : trimmedName,
            colorHex: Self.groupColorPalette[groups.count % Self.groupColorPalette.count]
        )
        groups.append(group)
        groups.sort { $0.createdAt < $1.createdAt }
        save()
        return group
    }

    func updateGroupColor(_ group: TaskGroup, colorHex: String) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].colorHex = colorHex
        save()
    }

    func setGroupCollapsed(_ group: TaskGroup, isCollapsed: Bool) {
        guard let index = groups.firstIndex(where: { $0.id == group.id }) else { return }
        groups[index].isCollapsed = isCollapsed
        save()
    }

    func toggleGroupCollapsed(_ group: TaskGroup) {
        setGroupCollapsed(group, isCollapsed: !group.isCollapsed)
    }

    @discardableResult
    func addTask(
        title: String,
        notes: String,
        groupID: UUID,
        dueDate: Date?,
        link: URL?,
        status: TaskStatus = .todo,
        priority: TaskPriority = .normal
    ) -> TaskItem {
        let resolvedGroupID = groups.contains(where: { $0.id == groupID }) ? groupID : defaultGroupID
        let task = TaskItem(
            groupID: resolvedGroupID,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            link: link,
            status: status,
            priority: priority
        )
        tasks.append(task)
        save()
        return task
    }

    func updateTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        var updatedTask = task
        updatedTask.updatedAt = .now
        tasks[index] = updatedTask
        save()
    }

    func updateStatus(for task: TaskItem, to status: TaskStatus) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].status = status
        tasks[index].updatedAt = .now
        save()
    }

    func updatePriority(for task: TaskItem, to priority: TaskPriority) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].priority = priority
        tasks[index].updatedAt = .now
        save()
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        save()
    }

    func deleteGroup(_ group: TaskGroup) {
        let fallbackID = ensureDefaultGroup()
        guard group.id != fallbackID else { return }
        for index in tasks.indices where tasks[index].groupID == group.id {
            tasks[index].groupID = fallbackID
            tasks[index].updatedAt = .now
        }
        groups.removeAll { $0.id == group.id }
        save()
    }

    func resetData() {
        groups = [TaskGroup(name: "General", createdAt: .distantPast, colorHex: "#3B82F6")]
        tasks = []
        save()
    }

    func load() {
        do {
            let snapshot = try storage.load()
            groups = snapshot.groups
            tasks = snapshot.tasks
            let defaultGroupID = ensureDefaultGroup(saveAfterCreating: false)
            let groupIDs = Set(groups.map(\.id))
            var repairedDanglingTasks = false
            for index in tasks.indices where !groupIDs.contains(tasks[index].groupID) {
                tasks[index].groupID = defaultGroupID
                tasks[index].updatedAt = .now
                repairedDanglingTasks = true
            }
            if repairedDanglingTasks {
                save()
            }
        } catch {
            groups = [TaskGroup(name: "General")]
            tasks = []
            lastError = error.localizedDescription
        }
    }

    private func ensureDefaultGroup(saveAfterCreating: Bool = true) -> UUID {
        if let existing = groups.first(where: { $0.name.caseInsensitiveCompare("General") == .orderedSame }) {
            return existing.id
        }

        let group = TaskGroup(name: "General", createdAt: .distantPast, colorHex: "#3B82F6")
        groups.insert(group, at: 0)
        if saveAfterCreating {
            save()
        }
        return group.id
    }

    private func save() {
        do {
            try storage.save(TaskSnapshot(groups: groups, tasks: tasks))
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    private func sorted(_ tasks: [TaskItem]) -> [TaskItem] {
        tasks.sorted { lhs, rhs in
            if lhs.status == .completed && rhs.status != .completed {
                return false
            }
            if lhs.status != .completed && rhs.status == .completed {
                return true
            }
            if lhs.priority == .high && rhs.priority != .high {
                return true
            }
            if lhs.priority != .high && rhs.priority == .high {
                return false
            }
            if lhs.priority == .high && rhs.priority == .high {
                return lhs.createdAt < rhs.createdAt
            }
            switch (lhs.dueDate, rhs.dueDate) {
            case let (lhsDate?, rhsDate?):
                if lhsDate != rhsDate { return lhsDate < rhsDate }
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            case (nil, nil):
                break
            }
            return lhs.createdAt < rhs.createdAt
        }
    }

    private func isSameDay(_ date: Date?, as comparisonDate: Date) -> Bool {
        guard let date else { return false }
        return Calendar.current.isDate(date, inSameDayAs: comparisonDate)
    }

    private static let groupColorPalette = [
        "#3B82F6",
        "#EF4444",
        "#10B981",
        "#F59E0B",
        "#8B5CF6",
        "#EC4899",
        "#06B6D4",
        "#64748B"
    ]
}

struct TaskSnapshot: Codable {
    var groups: [TaskGroup]
    var tasks: [TaskItem]
}

final class TaskStorage {
    private let fileManager: FileManager
    private let directoryURL: URL?
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default, directoryURL: URL? = nil) {
        self.fileManager = fileManager
        self.directoryURL = directoryURL
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func load() throws -> TaskSnapshot {
        let fileURL = try dataFileURL()
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return TaskSnapshot(groups: [TaskGroup(name: "General")], tasks: [])
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(TaskSnapshot.self, from: data)
    }

    func save(_ snapshot: TaskSnapshot) throws {
        let directoryURL = try supportDirectoryURL()
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        let data = try encoder.encode(snapshot)
        try data.write(to: directoryURL.appendingPathComponent("tasks.json"), options: [.atomic])
    }

    private func dataFileURL() throws -> URL {
        try supportDirectoryURL().appendingPathComponent("tasks.json")
    }

    private func supportDirectoryURL() throws -> URL {
        if let directoryURL {
            return directoryURL
        }

        return try fileManager
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ToDoListApp", isDirectory: true)
    }
}

@MainActor
private final class TaskReminderScheduler {
    private weak var store: TaskStore?
    private var timer: Timer?

    func start(store: TaskStore) {
        self.store = store
        Task {
            await requestNotificationPermissionIfNeeded()
            scheduleNextReminder()
        }
    }

    private func requestNotificationPermissionIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let authorizationStatus = await notificationAuthorizationStatus()
        guard authorizationStatus == .notDetermined else { return }

        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            store?.lastError = error.localizedDescription
        }
    }

    private func scheduleNextReminder() {
        timer?.invalidate()

        let nextReminderDate = nextNineAM(after: .now)
        let interval = max(nextReminderDate.timeIntervalSinceNow, 1)
        let timer = Timer(timeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                await self?.publishReminders()
                self?.scheduleNextReminder()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func nextNineAM(after date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = 9
        components.minute = 0
        components.second = 0

        let todayAtNine = calendar.date(from: components) ?? date
        if todayAtNine > date {
            return todayAtNine
        }
        return calendar.date(byAdding: .day, value: 1, to: todayAtNine) ?? date.addingTimeInterval(86_400)
    }

    private func publishReminders() async {
        let center = UNUserNotificationCenter.current()
        let authorizationStatus = await notificationAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            return
        }

        guard let store else { return }
        let date = Date()
        for task in store.reminderTasks(for: date) {
            let content = UNMutableNotificationContent()
            content.title = task.title
            content.body = notificationBody(for: task, date: date, store: store)
            content.sound = .default

            let identifier = reminderIdentifier(for: task, date: date)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
            do {
                try await center.add(request)
            } catch {
                store.lastError = error.localizedDescription
            }
        }
    }

    private func notificationAuthorizationStatus() async -> UNAuthorizationStatus {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus)
            }
        }
    }

    private func notificationBody(for task: TaskItem, date: Date, store: TaskStore) -> String {
        let groupName = store.groupName(for: task.groupID)
        let isDueToday = Calendar.current.isDate(task.dueDate ?? .distantPast, inSameDayAs: date)

        switch (task.priority == .high, isDueToday) {
        case (true, true):
            return "High priority and due today in \(groupName)."
        case (true, false):
            return "High priority task in \(groupName)."
        case (false, true):
            return "Due today in \(groupName)."
        case (false, false):
            return groupName
        }
    }

    private func reminderIdentifier(for task: TaskItem, date: Date) -> String {
        let day = Calendar.current.ordinality(of: .day, in: .era, for: date) ?? 0
        return "daily-reminder-\(day)-\(task.id.uuidString)"
    }
}
