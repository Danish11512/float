import Foundation

protocol APIClienting: AnyObject, Sendable {
    func fetch<T: Decodable & Sendable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T
}

enum APIEndpoint {
    // TODO: Define endpoints
}

actor APIClient: APIClienting {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch<T: Decodable & Sendable>(_ endpoint: APIEndpoint, as type: T.Type) async throws -> T {
        // TODO: Build URL from endpoint, decode response
        throw URLError(.badURL)
    }
}
