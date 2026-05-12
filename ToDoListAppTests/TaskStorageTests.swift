import XCTest
@testable import To_Do_List

final class TaskStorageTests: XCTestCase {
    private var temporaryDirectory: URL!
    private var storage: TaskStorage!

    override func setUpWithError() throws {
        try super.setUpWithError()
        temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ToDoListAppStorageTests-\(UUID().uuidString)", isDirectory: true)
        storage = TaskStorage(directoryURL: temporaryDirectory)
    }

    override func tearDownWithError() throws {
        if let temporaryDirectory {
            try? FileManager.default.removeItem(at: temporaryDirectory)
        }
        storage = nil
        temporaryDirectory = nil
        try super.tearDownWithError()
    }

    func testLoadReturnsDefaultSnapshotWhenFileDoesNotExist() throws {
        let snapshot = try storage.load()

        XCTAssertEqual(snapshot.groups.count, 1)
        XCTAssertEqual(snapshot.groups.first?.name, "General")
        XCTAssertTrue(snapshot.tasks.isEmpty)
    }

    func testSaveCreatesDirectoryAndPersistsPrettyPrintedSnapshot() throws {
        let group = TaskGroup(name: "Project", colorHex: "#EF4444", isCollapsed: true)
        let task = TaskItem(groupID: group.id, title: "Persist me", priority: .high)
        let snapshot = TaskSnapshot(groups: [group], tasks: [task])

        try storage.save(snapshot)

        let dataFile = temporaryDirectory.appendingPathComponent("tasks.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: dataFile.path))
        let json = try String(contentsOf: dataFile, encoding: .utf8)
        XCTAssertTrue(json.contains("\"groups\""))
        XCTAssertTrue(json.contains("\"tasks\""))
    }

    func testSavedSnapshotLoadsWithAllGroupsAndTasks() throws {
        let timestamp = Date(timeIntervalSince1970: 1_700_000_000)
        let group = TaskGroup(name: "Project", createdAt: timestamp, colorHex: "#10B981", isCollapsed: true)
        let task = TaskItem(
            groupID: group.id,
            title: "Stored task",
            notes: "Details",
            dueDate: timestamp,
            link: URL(string: "https://example.com")!,
            status: .inProgress,
            priority: .low,
            createdAt: timestamp,
            updatedAt: timestamp
        )
        let snapshot = TaskSnapshot(groups: [group], tasks: [task])

        try storage.save(snapshot)
        let loaded = try storage.load()

        XCTAssertEqual(loaded.groups, [group])
        XCTAssertEqual(loaded.tasks, [task])
    }

    func testLoadThrowsForInvalidJSON() throws {
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: temporaryDirectory.appendingPathComponent("tasks.json"))

        XCTAssertThrowsError(try storage.load())
    }
}
