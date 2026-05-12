import Foundation

struct TaskGroup: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var createdAt: Date
    var colorHex: String
    var isCollapsed: Bool

    init(
        id: UUID = UUID(),
        name: String,
        createdAt: Date = .now,
        colorHex: String = "#3B82F6",
        isCollapsed: Bool = false
    ) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.colorHex = colorHex
        self.isCollapsed = isCollapsed
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt
        case colorHex
        case isCollapsed
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        colorHex = try container.decodeIfPresent(String.self, forKey: .colorHex) ?? "#3B82F6"
        isCollapsed = try container.decodeIfPresent(Bool.self, forKey: .isCollapsed) ?? false
    }
}
