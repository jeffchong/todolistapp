import XCTest
@testable import To_Do_List

final class ModelCodingTests: XCTestCase {
    private let isoDate = "2026-05-12T09:30:00Z"

    func testTaskItemDecodesMissingPriorityAsNormalForLegacyData() throws {
        let groupID = UUID()
        let taskID = UUID()
        let json = """
        {
          "id": "\(taskID.uuidString)",
          "groupID": "\(groupID.uuidString)",
          "title": "Legacy task",
          "notes": "Created before priorities existed",
          "dueDate": null,
          "link": null,
          "status": "To Do",
          "createdAt": "\(isoDate)",
          "updatedAt": "\(isoDate)"
        }
        """

        let task = try decoder.decode(TaskItem.self, from: Data(json.utf8))

        XCTAssertEqual(task.id, taskID)
        XCTAssertEqual(task.groupID, groupID)
        XCTAssertEqual(task.priority, .normal)
    }

    func testTaskItemRoundTripsPriorityStatusDueDateAndLink() throws {
        let dueDate = ISO8601DateFormatter().date(from: isoDate)!
        let task = TaskItem(
            groupID: UUID(),
            title: "Round trip",
            notes: "Details",
            dueDate: dueDate,
            link: URL(string: "https://example.com/task")!,
            status: .blocked,
            priority: .high,
            createdAt: dueDate,
            updatedAt: dueDate
        )

        let data = try encoder.encode(task)
        let decoded = try decoder.decode(TaskItem.self, from: data)

        XCTAssertEqual(decoded, task)
    }

    func testTaskGroupDecodesMissingColorAndCollapsedStateForLegacyData() throws {
        let id = UUID()
        let json = """
        {
          "id": "\(id.uuidString)",
          "name": "Legacy group",
          "createdAt": "\(isoDate)"
        }
        """

        let group = try decoder.decode(TaskGroup.self, from: Data(json.utf8))

        XCTAssertEqual(group.id, id)
        XCTAssertEqual(group.name, "Legacy group")
        XCTAssertEqual(group.colorHex, "#3B82F6")
        XCTAssertFalse(group.isCollapsed)
    }

    func testTaskStatusMetadataIsStable() {
        XCTAssertEqual(TaskStatus.todo.systemImage, "circle")
        XCTAssertEqual(TaskStatus.inProgress.systemImage, "clock")
        XCTAssertEqual(TaskStatus.completed.systemImage, "checkmark.circle.fill")
        XCTAssertEqual(TaskStatus.blocked.systemImage, "exclamationmark.octagon")
    }

    func testTaskPriorityMetadataIsStable() {
        XCTAssertEqual(TaskPriority.low.systemImage, "arrow.down.circle")
        XCTAssertEqual(TaskPriority.normal.systemImage, "minus.circle")
        XCTAssertEqual(TaskPriority.high.systemImage, "arrow.up.circle.fill")
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
