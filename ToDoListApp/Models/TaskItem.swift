import SwiftUI

enum TaskPriority: String, CaseIterable, Codable, Identifiable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .low:
            "arrow.down.circle"
        case .normal:
            "minus.circle"
        case .high:
            "arrow.up.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low:
            .secondary
        case .normal:
            .blue
        case .high:
            .orange
        }
    }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var groupID: UUID
    var title: String
    var notes: String
    var dueDate: Date?
    var link: URL?
    var status: TaskStatus
    var priority: TaskPriority
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        groupID: UUID,
        title: String,
        notes: String = "",
        dueDate: Date? = nil,
        link: URL? = nil,
        status: TaskStatus = .todo,
        priority: TaskPriority = .normal,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.groupID = groupID
        self.title = title
        self.notes = notes
        self.dueDate = dueDate
        self.link = link
        self.status = status
        self.priority = priority
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case groupID
        case title
        case notes
        case dueDate
        case link
        case status
        case priority
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        groupID = try container.decode(UUID.self, forKey: .groupID)
        title = try container.decode(String.self, forKey: .title)
        notes = try container.decode(String.self, forKey: .notes)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        link = try container.decodeIfPresent(URL.self, forKey: .link)
        status = try container.decode(TaskStatus.self, forKey: .status)
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .normal
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}
