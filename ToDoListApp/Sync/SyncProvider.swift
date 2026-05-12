import Foundation

enum SyncProviderKind: String, Codable, CaseIterable, Identifiable {
    case iCloud
    case oneDrivePersonal
    case oneDriveWork

    var id: String { rawValue }
}

struct SyncChangeSet: Codable {
    var snapshot: TaskSnapshot
    var changedAt: Date
}

protocol SyncProvider {
    var kind: SyncProviderKind { get }
    func fetchLatest() async throws -> SyncChangeSet?
    func push(_ changeSet: SyncChangeSet) async throws
}
