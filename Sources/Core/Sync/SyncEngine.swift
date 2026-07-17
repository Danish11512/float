import Foundation

actor SyncEngine {
    private let database: DatabaseManaging
    private let apiClient: APIClienting

    init(database: DatabaseManaging, apiClient: APIClienting) {
        self.database = database
        self.apiClient = apiClient
    }

    func sync() async {
        // TODO: Fetch from API, persist to local DB
        // Uses exponential backoff retry policy
    }
}
