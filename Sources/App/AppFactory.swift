import Foundation

@MainActor
final class AppFactory {
    let database: DatabaseManager
    let apiClient: APIClient
    let syncEngine: SyncEngine

    init() {
        self.database = DatabaseManager()
        self.apiClient = APIClient()
        self.syncEngine = SyncEngine(database: database, apiClient: apiClient)
    }
}
