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
    func testAddingTaskWithUnknownGroupUsesDefaultGroup() {
        withFixture { store in
            let task = store.addTask(
                title: "Orphan prevention",
                notes: "",
                groupID: UUID(),
                dueDate: nil,
                link: nil
            )

            XCTAssertEqual(task.groupID, store.defaultGroupID)
            XCTAssertEqual(store.tasks(for: store.groups[0]).map(\.id), [task.id])
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
    func testRenamingGroupTrimsNameAndIgnoresBlankName() {
        withFixture { store in
            let project = store.addGroup(named: "Project")

            store.renameGroup(project, to: "  Roadmap  ")
            XCTAssertEqual(store.groups.first(where: { $0.id == project.id })?.name, "Roadmap")

            store.renameGroup(project, to: "   ")
            XCTAssertEqual(store.groups.first(where: { $0.id == project.id })?.name, "Roadmap")
        }
    }

    @MainActor
    func testDeletingGeneralGroupIsIgnored() {
        withFixture { store in
            let general = store.groups[0]

            XCTAssertFalse(store.canDeleteGroup(general))
            store.deleteGroup(general)

            XCTAssertEqual(store.groups.map(\.id), [general.id])
        }
    }

    @MainActor
    func testMoveGroupReordersCustomGroupsAndKeepsGeneralAtTop() {
        withFixture { store in
            let general = store.groups[0]
            let alpha = store.addGroup(named: "Alpha")
            let beta = store.addGroup(named: "Beta")
            let gamma = store.addGroup(named: "Gamma")

            store.moveGroup(id: gamma.id, to: 1)

            XCTAssertEqual(store.groups.map(\.id), [general.id, gamma.id, alpha.id, beta.id])

            store.moveGroup(id: general.id, to: 3)

            XCTAssertEqual(store.groups.map(\.id), [general.id, gamma.id, alpha.id, beta.id])

            store.moveGroup(id: alpha.id, to: 0)

            XCTAssertEqual(store.groups.map(\.id), [general.id, alpha.id, gamma.id, beta.id])
        }
    }

    @MainActor
    func testAddingGroupAfterManualReorderPreservesExistingOrder() {
        withFixture { store in
            let general = store.groups[0]
            let alpha = store.addGroup(named: "Alpha")
            let beta = store.addGroup(named: "Beta")

            store.moveGroup(id: beta.id, to: 1)
            let gamma = store.addGroup(named: "Gamma")

            XCTAssertEqual(store.groups.map(\.id), [general.id, beta.id, alpha.id, gamma.id])
        }
    }

    @MainActor
    func testGroupOrderPersistsAcrossReloads() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let storage = TaskStorage(directoryURL: temporaryDirectory)
            let store = TaskStore(storage: storage, startsReminderScheduler: false)
            let general = store.groups[0]
            let alpha = store.addGroup(named: "Alpha")
            let beta = store.addGroup(named: "Beta")

            store.moveGroup(id: beta.id, to: 1)

            let reloadedStore = TaskStore(storage: storage, startsReminderScheduler: false)

            XCTAssertEqual(reloadedStore.groups.map(\.id), [general.id, beta.id, alpha.id])
        }
    }

    @MainActor
    func testLoadMovesExistingGeneralGroupToTop() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let project = TaskGroup(name: "Project")
            let general = TaskGroup(name: "General")
            let later = TaskGroup(name: "Later")
            let storage = TaskStorage(directoryURL: temporaryDirectory)
            try storage.save(TaskSnapshot(groups: [project, general, later], tasks: []))

            let store = TaskStore(storage: storage, startsReminderScheduler: false)

            XCTAssertEqual(store.groups.map(\.id), [general.id, project.id, later.id])
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
    func testLoadErrorDoesNotOverwriteExistingStorageFile() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let dataFile = temporaryDirectory.appendingPathComponent("tasks.json")
            try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
            try Data("not json".utf8).write(to: dataFile)

            let store = TaskStore(
                storage: TaskStorage(directoryURL: temporaryDirectory),
                startsReminderScheduler: false
            )

            XCTAssertEqual(store.groups.map(\.name), ["General"])
            XCTAssertTrue(store.tasks.isEmpty)
            XCTAssertNotNil(store.lastError)
            XCTAssertEqual(try String(contentsOf: dataFile, encoding: .utf8), "not json")
        }
    }

    @MainActor
    func testLoadRepairsTasksWithMissingGroupsToGeneral() throws {
        try withTemporaryDirectory { temporaryDirectory in
            let missingGroupID = UUID()
            let task = TaskItem(groupID: missingGroupID, title: "Needs a home")
            try TaskStorage(directoryURL: temporaryDirectory).save(TaskSnapshot(groups: [], tasks: [task]))

            let store = TaskStore(
                storage: TaskStorage(directoryURL: temporaryDirectory),
                startsReminderScheduler: false
            )

            XCTAssertEqual(store.groups.map(\.name), ["General"])
            XCTAssertEqual(store.tasks.map(\.groupID), [store.defaultGroupID])

            let loadedSnapshot = try TaskStorage(directoryURL: temporaryDirectory).load()
            XCTAssertEqual(loadedSnapshot.tasks.map(\.groupID), [store.defaultGroupID])
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

    private func withTemporaryDirectory(_ body: (URL) throws -> Void) throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ToDoListAppTests-\(UUID().uuidString)", isDirectory: true)
        defer {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        try body(temporaryDirectory)
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
