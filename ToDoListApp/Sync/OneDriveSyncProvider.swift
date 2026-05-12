import Foundation

final class OneDriveSyncProvider: SyncProvider {
    let kind: SyncProviderKind

    init(kind: SyncProviderKind) {
        precondition(kind == .oneDrivePersonal || kind == .oneDriveWork)
        self.kind = kind
    }

    func fetchLatest() async throws -> SyncChangeSet? {
        nil
    }

    func push(_ changeSet: SyncChangeSet) async throws {
        _ = changeSet
    }
}
