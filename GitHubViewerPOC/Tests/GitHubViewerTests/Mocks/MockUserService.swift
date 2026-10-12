//
//  Untitled.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation
@testable import GitHubViewerPOC

final class MockUserService: UserServiceProtocol {
    var shouldFail: Bool = false
    var mockUsers: [GitHubUser] = [
        GitHubUser(id: 1, login: "torvalds", avatarUrl: nil, htmlUrl: nil, name: "Linus", bio: "Linux", publicRepos: 50, followers: 150000, following: 0)
    ]

    func fetchUsers() async throws -> [GitHubUser] {
        if shouldFail { throw NetworkError.serverError(statusCode: 500) }
        return mockUsers
    }

    func fetchUserDetails(username: String) async throws -> GitHubUser {
        if shouldFail { throw NetworkError.serverError(statusCode: 404) }
        guard let user = mockUsers.first(where: { $0.login == username }) else {
            throw NetworkError.parsingError
        }
        return user
    }
}
