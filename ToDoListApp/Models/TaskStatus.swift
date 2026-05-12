import SwiftUI

enum TaskStatus: String, CaseIterable, Codable, Identifiable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case completed = "Completed"
    case blocked = "Blocked"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .todo:
            "circle"
        case .inProgress:
            "clock"
        case .completed:
            "checkmark.circle.fill"
        case .blocked:
            "exclamationmark.octagon"
        }
    }

    var color: Color {
        switch self {
        case .todo:
            .secondary
        case .inProgress:
            .blue
        case .completed:
            .green
        case .blocked:
            .red
        }
    }
}
