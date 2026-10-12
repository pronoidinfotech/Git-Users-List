//
//  UserDetailViewModelTests.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import XCTest
@testable import GitHubViewerPOC


@MainActor
final class UserDetailViewModelTests: XCTestCase {
    private var mockService: MockUserService!
    private var initialUser: GitHubUser!
    private var sut: UserDetailViewModel!

    override func setUp() {
        super.setUp()
        mockService = MockUserService()
        initialUser = GitHubUser(id: 1, login: "torvalds", avatarUrl: nil, htmlUrl: nil, name: nil, bio: nil, publicRepos: nil, followers: nil, following: nil)
        sut = UserDetailViewModel(user: initialUser, userService: mockService)
    }

    override func tearDown() {
        sut = nil
        initialUser = nil
        mockService = nil
        super.tearDown()
    }

    func testLoadUserDetailsSuccess() async {
        await sut.loadUserDetails()

        XCTAssertEqual(sut.user.name, "Linus")
        XCTAssertEqual(sut.user.publicRepos, 50)
        if case .loaded(let user) = sut.state {
            XCTAssertEqual(user.bio, "Linux")
        } else {
            XCTFail("Expected .loaded state")
        }
    }

    func testLoadUserDetailsFailure() async {
        mockService.shouldFail = true
        await sut.loadUserDetails()

        if case .error(let message) = sut.state {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected .error state")
        }
    }
}
