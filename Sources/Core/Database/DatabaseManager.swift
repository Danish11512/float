import Foundation

protocol DatabaseManaging: AnyObject, Sendable {
    func save<T: Encodable & Sendable>(_ item: T, table: String) async throws
    func fetch<T: Decodable & Sendable>(table: String, as type: T.Type) async throws -> [T]
}

actor DatabaseManager: DatabaseManaging {
    // GRDB DatabaseQueue will be initialized here
    // For now, stub implementation

    func save<T: Encodable & Sendable>(_ item: T, table: String) async throws {
        // TODO: Implement GRDB insert
    }

    func fetch<T: Decodable & Sendable>(table: String, as type: T.Type) async throws -> [T] {
        // TODO: Implement GRDB fetch
        return []
    }
}
