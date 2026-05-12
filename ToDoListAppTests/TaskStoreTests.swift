import XCTest
@testable import To_Do_List

@MainActor
final class TaskStoreTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var store: TaskStore!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ToDoListAppTests-\(UUID().uuidString)", isDirectory: true)
        store = TaskStore(
            storage: TaskStorage(directoryURL: temporaryDirectory),
            startsReminderScheduler: false
        )
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        store = nil
        temporaryDirectory = nil
        try super.tearDownWithError()
    }

    func testInitialLoadCreatesGeneralGroupOnly() {
        XCTAssertEqual(store.groups.count, 1)
        XCTAssertEqual(store.groups.first?.name, "General")
        XCTAssertEqual(store.tasks.count, 0)
        XCTAssertEqual(store.openTasks.count, 0)
    }

    func testAddingGroupTrimsNameAndAssignsPaletteColor() {
        let group = store.addGroup(named: "  Project X  ")

        XCTAssertEqual(group.name, "Project X")
        XCTAssertTrue(store.groups.contains(group))
        XCTAssertEqual(group.colorHex, "#EF4444")
    }

    func testAddingBlankGroupUsesUntitledGroupFallback() {
        let group = store.addGroup(named: "   ")

        XCTAssertEqual(group.name, "Untitled Group")
    }

    func testAddingTaskTrimsTitleAndNotesAndUsesDefaultStatusAndPriority() {
        let groupID = store.defaultGroupID
        let task = store.addTask(
            title: "  Ship feature  ",
            notes: "  Check the edges  ",
            groupID: groupID,
            dueDate: nil,
            link: nil
        )

        XCTAssertEqual(task.title, "Ship feature")
        XCTAssertEqual(task.notes, "Check the edges")
        XCTAssertEqual(task.status, .todo)
        XCTAssertEqual(task.priority, .normal)
        XCTAssertEqual(store.tasks.count, 1)
    }

    func testOpenTasksExcludeCompletedTasks() {
        let groupID = store.defaultGroupID
        let openTask = store.addTask(title: "Open", notes: "", groupID: groupID, dueDate: nil, link: nil)
        let completedTask = store.addTask(title: "Done", notes: "", groupID: groupID, dueDate: nil, link: nil)

        store.updateStatus(for: completedTask, to: .completed)

        XCTAssertEqual(store.openTasks.map(\.id), [openTask.id])
        XCTAssertEqual(store.openTasks(for: store.groups[0]).map(\.id), [openTask.id])
        XCTAssertEqual(store.taskCount(for: store.groups[0]), 2)
        XCTAssertEqual(store.taskCount(for: store.groups[0], includeCompleted: false), 1)
    }

    func testHighPriorityTasksSortFirstInCreationOrderWithinGroup() {
        let groupID = store.defaultGroupID
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let low = addTask("Low", groupID: groupID, priority: .low, createdAt: base)
        let normal = addTask("Normal", groupID: groupID, priority: .normal, createdAt: base.addingTimeInterval(10))
        let highOne = addTask("High One", groupID: groupID, priority: .high, createdAt: base.addingTimeInterval(20))
        let highTwo = addTask("High Two", groupID: groupID, priority: .high, createdAt: base.addingTimeInterval(30))

        let sortedIDs = store.tasks(for: store.groups[0]).map(\.id)

        XCTAssertEqual(sortedIDs, [highOne.id, highTwo.id, low.id, normal.id])
    }

    func testNonHighTasksSortByDueDateThenCreationDate() {
        let groupID = store.defaultGroupID
        let base = Date(timeIntervalSince1970: 1_700_000_000)
        let undated = addTask("Undated", groupID: groupID, createdAt: base)
        let later = addTask("Later", groupID: groupID, dueDate: base.addingTimeInterval(86_400), createdAt: base.addingTimeInterval(10))
        let earlier = addTask("Earlier", groupID: groupID, dueDate: base, createdAt: base.addingTimeInterval(20))

        let sortedIDs = store.tasks(for: store.groups[0]).map(\.id)

        XCTAssertEqual(sortedIDs, [earlier.id, later.id, undated.id])
    }

    func testUpdatingStatusPriorityAndTaskPersistsChanges() {
        let task = store.addTask(title: "Task", notes: "", groupID: store.defaultGroupID, dueDate: nil, link: nil)

        store.updateStatus(for: task, to: .blocked)
        store.updatePriority(for: task, to: .high)
        var edited = store.tasks[0]
        edited.title = "Edited"
        edited.notes = "More detail"
        store.updateTask(edited)

        XCTAssertEqual(store.tasks[0].status, .blocked)
        XCTAssertEqual(store.tasks[0].priority, .high)
        XCTAssertEqual(store.tasks[0].title, "Edited")
        XCTAssertEqual(store.tasks[0].notes, "More detail")
    }

    func testDeletingGroupMovesTasksToGeneralAndPreservesDefaultGroup() {
        let project = store.addGroup(named: "Project")
        let task = store.addTask(title: "Move me", notes: "", groupID: project.id, dueDate: nil, link: nil)

        store.deleteGroup(project)

        XCTAssertFalse(store.groups.contains(project))
        XCTAssertEqual(store.groups.count, 1)
        XCTAssertEqual(store.tasks.first(where: { $0.id == task.id })?.groupID, store.defaultGroupID)
    }

    func testDeletingGeneralGroupIsIgnored() {
        let general = store.groups[0]

        store.deleteGroup(general)

        XCTAssertEqual(store.groups.map(\.id), [general.id])
    }

    func testResetDataClearsTasksAndCustomGroups() {
        let project = store.addGroup(named: "Project")
        store.addTask(title: "Task", notes: "", groupID: project.id, dueDate: nil, link: nil)

        store.resetData()

        XCTAssertEqual(store.groups.count, 1)
        XCTAssertEqual(store.groups.first?.name, "General")
        XCTAssertEqual(store.groups.first?.colorHex, "#3B82F6")
        XCTAssertTrue(store.tasks.isEmpty)
    }

    func testReminderTasksIncludeOpenHighPriorityAndDueTodayTasksOnlyOnce() {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        let groupID = store.defaultGroupID

        let high = addTask("High", groupID: groupID, priority: .high)
        let dueToday = addTask("Due Today", groupID: groupID, dueDate: now)
        let highDueToday = addTask("High Due Today", groupID: groupID, dueDate: now, priority: .high)
        addTask("Due Tomorrow", groupID: groupID, dueDate: tomorrow)
        let completedHigh = addTask("Completed High", groupID: groupID, priority: .high)
        store.updateStatus(for: completedHigh, to: .completed)

        let reminderIDs = store.reminderTasks(for: now).map(\.id)

        XCTAssertEqual(reminderIDs, [high.id, highDueToday.id, dueToday.id])
        XCTAssertEqual(Set(reminderIDs).count, reminderIDs.count)
    }

    func testGroupsWithoutOpenTasksCountTracksOpenTasksByGroup() {
        let project = store.addGroup(named: "Project")
        let task = store.addTask(title: "Task", notes: "", groupID: project.id, dueDate: nil, link: nil)

        XCTAssertEqual(store.groupsWithoutOpenTasksCount, 1)

        store.updateStatus(for: task, to: .completed)

        XCTAssertEqual(store.groupsWithoutOpenTasksCount, 2)
    }

    @discardableResult
    private func addTask(
        _ title: String,
        groupID: UUID,
        dueDate: Date? = nil,
        status: TaskStatus = .todo,
        priority: TaskPriority = .normal,
        createdAt: Date = .now
    ) -> TaskItem {
        let task = TaskItem(
            groupID: groupID,
            title: title,
            dueDate: dueDate,
            status: status,
            priority: priority,
            createdAt: createdAt,
            updatedAt: createdAt
        )
        store.addTask(
            title: task.title,
            notes: task.notes,
            groupID: task.groupID,
            dueDate: task.dueDate,
            link: task.link,
            status: task.status,
            priority: task.priority
        )
        var storedTask = store.tasks.last!
        storedTask.createdAt = createdAt
        storedTask.updatedAt = createdAt
        store.updateTask(storedTask)
        return storedTask
    }
}
