//
//  AppCoordinator.swift
//  GitHubViewerPOC
//
//  Created by pradnya Kharche on 11/10/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var navigationPath = NavigationPath()
    
    let userService: UserServiceProtocol
    let networkMonitor: NetworkMonitor
    let jailbreakDetector: JailbreakDetecting

    init(
        userService: UserServiceProtocol = UserService(),
        networkMonitor: NetworkMonitor = NetworkMonitor(),
        jailbreakDetector: JailbreakDetecting = JailbreakDetector()
    ) {
        self.userService = userService
        self.networkMonitor = networkMonitor
        self.jailbreakDetector = jailbreakDetector
    }

    // Navigation Actions
    func showDetail(for user: GitHubUser) {
        navigationPath.append(AppRoute.detail(user: user))
    }

    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }

    // View Factory
    @ViewBuilder
    func buildStartView() -> some View {
        let viewModel = UserListViewModel(userService: userService, coordinator: self)
        UserListView(viewModel: viewModel, networkMonitor: networkMonitor, isJailbroken: jailbreakDetector.isJailbroken())
    }

    @ViewBuilder
    func buildDestinationView(for route: AppRoute) -> some View {
        switch route {
        case .detail(let user):
            let viewModel = UserDetailViewModel(user: user, userService: userService)
            UserDetailView(viewModel: viewModel)
        }
    }
}
