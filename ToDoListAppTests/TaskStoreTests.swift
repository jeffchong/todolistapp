import XCTest
@testable import To_Do_List

final class TaskStoreTests: XCTestCase {
    @MainActor
    func testInitialLoadCreatesGeneralGroupOnly() {
        withFixture { store in
            XCTAssertEqual(store.groups.count, 1)
            XCTAssertEqual(store.groups.first?.name, "General")
            XCTAssertEqual(store.tasks.count, 0)
            XCTAssertEqual(store.openTasks.count, 0)
        }
    }

    @MainActor
    func testAddingGroupTrimsNameAndAssignsPaletteColor() {
        withFixture { store in
            let group = store.addGroup(named: "  Project X  ")

            XCTAssertEqual(group.name, "Project X")
            XCTAssertTrue(store.groups.contains(group))
            XCTAssertEqual(group.colorHex, "#EF4444")
        }
    }

    @MainActor
    func testAddingBlankGroupUsesUntitledGroupFallback() {
        withFixture { store in
            let group = store.addGroup(named: "   ")

            XCTAssertEqual(group.name, "Untitled Group")
        }
    }

    @MainActor
    func testAddingTaskTrimsTitleAndNotesAndUsesDefaultStatusAndPriority() {
        withFixture { store in
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
    }

    @MainActor
    func testOpenTasksExcludeCompletedTasks() {
        withFixture { store in
            let groupID = store.defaultGroupID
            let openTask = store.addTask(title: "Open", notes: "", groupID: groupID, dueDate: nil, link: nil)
            let completedTask = store.addTask(title: "Done", notes: "", groupID: groupID, dueDate: nil, link: nil)

            store.updateStatus(for: completedTask, to: .completed)

            XCTAssertEqual(store.openTasks.map(\.id), [openTask.id])
            XCTAssertEqual(store.openTasks(for: store.groups[0]).map(\.id), [openTask.id])
            XCTAssertEqual(store.taskCount(for: store.groups[0]), 2)
            XCTAssertEqual(store.taskCount(for: store.groups[0], includeCompleted: false), 1)
        }
    }

    @MainActor
    func testHighPriorityTasksSortFirstInCreationOrderWithinGroup() {
        withFixture { store in
            let groupID = store.defaultGroupID
            let base = Date(timeIntervalSince1970: 1_700_000_000)
            let low = addTask("Low", store: store, groupID: groupID, priority: .low, createdAt: base)
            let normal = addTask(
                "Normal",
                store: store,
                groupID: groupID,
                priority: .normal,
                createdAt: base.addingTimeInterval(10)
            )
            let highOne = addTask(
                "High One",
                store: store,
                groupID: groupID,
                priority: .high,
                createdAt: base.addingTimeInterval(20)
            )
            let highTwo = addTask(
                "High Two",
                store: store,
                groupID: groupID,
                priority: .high,
                createdAt: base.addingTimeInterval(30)
            )

            let sortedIDs = store.tasks(for: store.groups[0]).map(\.id)

            XCTAssertEqual(sortedIDs, [highOne.id, highTwo.id, low.id, normal.id])
        }
    }

    @MainActor
    func testNonHighTasksSortByDueDateThenCreationDate() {
        withFixture { store in
            let groupID = store.defaultGroupID
            let base = Date(timeIntervalSince1970: 1_700_000_000)
            let undated = addTask("Undated", store: store, groupID: groupID, createdAt: base)
            let later = addTask(
                "Later",
                store: store,
                groupID: groupID,
                dueDate: base.addingTimeInterval(86_400),
                createdAt: base.addingTimeInterval(10)
            )
            let earlier = addTask(
                "Earlier",
                store: store,
                groupID: groupID,
                dueDate: base,
                createdAt: base.addingTimeInterval(20)
            )

            let sortedIDs = store.tasks(for: store.groups[0]).map(\.id)

            XCTAssertEqual(sortedIDs, [earlier.id, later.id, undated.id])
        }
    }

    @MainActor
    func testUpdatingStatusPriorityAndTaskPersistsChanges() {
        withFixture { store in
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
    }

    @MainActor
    func testDeletingGroupMovesTasksToGeneralAndPreservesDefaultGroup() {
        withFixture { store in
            let project = store.addGroup(named: "Project")
            let task = store.addTask(title: "Move me", notes: "", groupID: project.id, dueDate: nil, link: nil)

            store.deleteGroup(project)

            XCTAssertFalse(store.groups.contains(project))
            XCTAssertEqual(store.groups.count, 1)
            XCTAssertEqual(store.tasks.first(where: { $0.id == task.id })?.groupID, store.defaultGroupID)
        }
    }

    @MainActor
    func testDeletingGeneralGroupIsIgnored() {
        withFixture { store in
            let general = store.groups[0]

            store.deleteGroup(general)

            XCTAssertEqual(store.groups.map(\.id), [general.id])
        }
    }

    @MainActor
    func testResetDataClearsTasksAndCustomGroups() {
        withFixture { store in
            let project = store.addGroup(named: "Project")
            store.addTask(title: "Task", notes: "", groupID: project.id, dueDate: nil, link: nil)

            store.resetData()

            XCTAssertEqual(store.groups.count, 1)
            XCTAssertEqual(store.groups.first?.name, "General")
            XCTAssertEqual(store.groups.first?.colorHex, "#3B82F6")
            XCTAssertTrue(store.tasks.isEmpty)
        }
    }

    @MainActor
    func testReminderTasksIncludeOpenHighPriorityAndDueTodayTasksOnlyOnce() {
        withFixture { store in
            let now = Date(timeIntervalSince1970: 1_700_000_000)
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
            let groupID = store.defaultGroupID

            let high = addTask("High", store: store, groupID: groupID, priority: .high)
            let dueToday = addTask("Due Today", store: store, groupID: groupID, dueDate: now)
            let highDueToday = addTask("High Due Today", store: store, groupID: groupID, dueDate: now, priority: .high)
            addTask("Due Tomorrow", store: store, groupID: groupID, dueDate: tomorrow)
            let completedHigh = addTask("Completed High", store: store, groupID: groupID, priority: .high)
            store.updateStatus(for: completedHigh, to: .completed)

            let reminderIDs = store.reminderTasks(for: now).map(\.id)

            XCTAssertEqual(reminderIDs, [high.id, highDueToday.id, dueToday.id])
            XCTAssertEqual(Set(reminderIDs).count, reminderIDs.count)
        }
    }

    @MainActor
    func testGroupsWithoutOpenTasksCountTracksOpenTasksByGroup() {
        withFixture { store in
            let project = store.addGroup(named: "Project")
            let task = store.addTask(title: "Task", notes: "", groupID: project.id, dueDate: nil, link: nil)

            XCTAssertEqual(store.groupsWithoutOpenTasksCount, 1)

            store.updateStatus(for: task, to: .completed)

            XCTAssertEqual(store.groupsWithoutOpenTasksCount, 2)
        }
    }

    @MainActor
    private func withFixture(_ body: (TaskStore) -> Void) {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ToDoListAppTests-\(UUID().uuidString)", isDirectory: true)
        let store = TaskStore(
            storage: TaskStorage(directoryURL: temporaryDirectory),
            startsReminderScheduler: false
        )

        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }

        body(store)
    }

    @discardableResult
    @MainActor
    private func addTask(
        _ title: String,
        store: TaskStore,
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
