//
//  UserDetailViewModel.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation
import Combine

@MainActor
final class UserDetailViewModel: ObservableObject {
    @Published private(set) var state: ViewState<GitHubUser> = .idle
    @Published private(set) var user: GitHubUser

    private let userService: UserServiceProtocol

    init(user: GitHubUser, userService: UserServiceProtocol) {
        self.user = user
        self.userService = userService
    }

    func loadUserDetails() async {
        state = .loading
        do {
            let detailedUser = try await userService.fetchUserDetails(username: user.login)
            self.user = detailedUser
            state = .loaded(detailedUser)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
}
