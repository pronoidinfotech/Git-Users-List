//
//  UserListViewModelTests.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import XCTest
import SwiftUI
@testable import GitHubViewerPOC


@MainActor
final class UserListViewModelTests: XCTestCase {
    private var mockService: MockUserService!
    private var coordinator: AppCoordinator!
    private var sut: UserListViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockUserService()
        coordinator = AppCoordinator(userService: mockService)
        sut = UserListViewModel(userService: mockService, coordinator: coordinator)
    }

    override func tearDown() {
        sut = nil
        coordinator = nil
        mockService = nil
        super.tearDown()
    }

    func testLoadUsersSuccess() async {
        XCTAssertEqual(sut.state, .idle)
        await sut.loadUsers()

        if case .loaded(let users) = sut.state {
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users.first?.login, "torvalds")
        } else {
            XCTFail("State should be .loaded")
        }
    }

    func testLoadUsersFailure() async {
        mockService.shouldFail = true
        await sut.loadUsers()

        if case .error(let msg) = sut.state {
            XCTAssertFalse(msg.isEmpty)
        } else {
            XCTFail("State should be .error")
        }
    }

    func testDidSelectUserNavigatesViaCoordinator() {
        let user = mockService.mockUsers[0]
        XCTAssertTrue(coordinator.navigationPath.isEmpty)

        sut.didSelectUser(user)

        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }
}
