//
//  UserListViewModel.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation
import Combine

@MainActor
final class UserListViewModel: ObservableObject {
    @Published private(set) var state: ViewState<[GitHubUser]> = .idle

    private let userService: UserServiceProtocol
    private weak var coordinator: AppCoordinator?

    init(userService: UserServiceProtocol, coordinator: AppCoordinator?) {
        self.userService = userService
        self.coordinator = coordinator
    }

    func loadUsers() async {
        state = .loading
        do {
            let users = try await userService.fetchUsers()
            state = .loaded(users)
        } catch {
            state = .error(error.localizedDescription)
        }
    }

    func didSelectUser(_ user: GitHubUser) {
        coordinator?.showDetail(for: user)
    }
}
