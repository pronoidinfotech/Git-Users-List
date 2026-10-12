import Foundation

protocol UserServiceProtocol {
    func fetchUsers() async throws -> [GitHubUser]
    func fetchUserDetails(username: String) async throws -> GitHubUser
}

final class UserService: UserServiceProtocol {
    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol = APIClient()) {
        self.apiClient = apiClient
    }

    func fetchUsers() async throws -> [GitHubUser] {
        guard let url = URL(string: "https://api.github.com/users?per_page=30") else {
            throw NetworkError.invalidURL
        }
        return try await apiClient.request(url: url)
    }

    func fetchUserDetails(username: String) async throws -> GitHubUser {
        guard let url = URL(string: "https://api.github.com/users/\(username)") else {
            throw NetworkError.invalidURL
        }
        return try await apiClient.request(url: url)
    }
}
