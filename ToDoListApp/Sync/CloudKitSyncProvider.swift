import CloudKit
import Foundation

final class CloudKitSyncProvider: SyncProvider {
    let kind: SyncProviderKind = .iCloud

    private let container: CKContainer

    init(container: CKContainer = .default()) {
        self.container = container
    }

    func fetchLatest() async throws -> SyncChangeSet? {
        _ = container
        return nil
    }

    func push(_ changeSet: SyncChangeSet) async throws {
        _ = changeSet
        _ = container
    }
}
