//
//  GitHubViewerPOCTests.swift
//  GitHubViewerPOCTests
//
//  Created by praful kharche on 11/10/26.
//

import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import GitHubViewerPOC

@MainActor
final class APIClientTests: XCTestCase {
    private var session: URLSession!
    private var sut: APIClient!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        session = URLSession(configuration: configuration)
        sut = APIClient(session: session)
    }

    override func tearDown() {
        StubURLProtocol.requestHandler = nil
        session.invalidateAndCancel()
        session = nil
        sut = nil
        super.tearDown()
    }

    func testRequestDecodesSuccessfulResponseAndSetsGitHubAcceptHeader() async throws {
        let data = Data(
            """
            [{"id":1,"login":"octocat","avatar_url":"avatar","html_url":"profile"}]
            """.utf8
        )
        StubURLProtocol.requestHandler = { request in
            XCTAssertEqual(
                request.value(forHTTPHeaderField: "Accept"),
                "application/vnd.github.v3+json"
            )
            return (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, data)
        }

        let users: [GitHubUser] = try await sut.request(url: URL(string: "https://api.github.com/users")!)

        XCTAssertEqual(users.count, 1)
        XCTAssertEqual(users.first?.login, "octocat")
        XCTAssertEqual(users.first?.avatarUrl, "avatar")
        XCTAssertEqual(users.first?.htmlUrl, "profile")
    }

    func testRequestThrowsServerErrorForNonSuccessfulStatusCode() async {
        StubURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 403, httpVersion: nil, headerFields: nil)!, Data())
        }

        do {
            let _: [GitHubUser] = try await sut.request(url: URL(string: "https://api.github.com/users")!)
            XCTFail("Expected a server error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .serverError(statusCode: 403))
        }
    }

    func testRequestThrowsParsingErrorForMalformedJSON() async {
        StubURLProtocol.requestHandler = { request in
            (HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, Data("not-json".utf8))
        }

        do {
            let _: [GitHubUser] = try await sut.request(url: URL(string: "https://api.github.com/users")!)
            XCTFail("Expected a parsing error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .parsingError)
        }
    }

    func testRequestWrapsTransportFailureAsConnectivityIssue() async {
        StubURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        do {
            let _: [GitHubUser] = try await sut.request(url: URL(string: "https://api.github.com/users")!)
            XCTFail("Expected a connectivity error")
        } catch let NetworkError.connectivityIssue(message) {
            XCTAssertFalse(message.isEmpty)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testRequestThrowsServerErrorForNonHTTPResponse() async {
        StubURLProtocol.requestHandler = { request in
            (URLResponse(url: request.url!, mimeType: nil, expectedContentLength: 0, textEncodingName: nil), Data())
        }

        do {
            let _: [GitHubUser] = try await sut.request(url: URL(string: "https://api.github.com/users")!)
            XCTFail("Expected a server error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .serverError(statusCode: -1))
        }
    }
}

@MainActor
final class UserServiceTests: XCTestCase {
    private var apiClient: RecordingAPIClient!
    private var sut: UserService!

    override func setUp() {
        super.setUp()
        apiClient = RecordingAPIClient()
        sut = UserService(apiClient: apiClient)
    }

    override func tearDown() {
        sut = nil
        apiClient = nil
        super.tearDown()
    }

    func testFetchUsersRequestsExpectedEndpointAndDecodesUsers() async throws {
        apiClient.responseData = Data("[{\"id\":1,\"login\":\"octocat\"}]".utf8)

        let users = try await sut.fetchUsers()

        XCTAssertEqual(users.map(\.login), ["octocat"])
        XCTAssertEqual(apiClient.requestedURL?.host, "api.github.com")
        XCTAssertEqual(apiClient.requestedURL?.path, "/users")
        XCTAssertEqual(apiClient.requestedURL?.query, "per_page=30")
    }

    func testFetchUserDetailsUsesUsernameInEndpoint() async throws {
        apiClient.responseData = Data("{\"id\":1,\"login\":\"octocat\"}".utf8)

        let user = try await sut.fetchUserDetails(username: "octocat")

        XCTAssertEqual(user.login, "octocat")
        XCTAssertEqual(apiClient.requestedURL?.absoluteString, "https://api.github.com/users/octocat")
    }

    func testServiceForwardsAPIClientError() async {
        apiClient.error = NetworkError.serverError(statusCode: 503)

        do {
            _ = try await sut.fetchUsers()
            XCTFail("Expected the API client error")
        } catch {
            XCTAssertEqual(error as? NetworkError, .serverError(statusCode: 503))
        }
    }
}

@MainActor
final class AppCoordinatorTests: XCTestCase {
    private var coordinator: AppCoordinator!
    private var user: GitHubUser!

    override func setUp() {
        super.setUp()
        coordinator = AppCoordinator(
            userService: MockUserService(),
            networkMonitor: NetworkMonitor(),
            jailbreakDetector: StubJailbreakDetector()
        )
        user = GitHubUser(
            id: 1,
            login: "octocat",
            avatarUrl: nil,
            htmlUrl: nil,
            name: nil,
            bio: nil,
            publicRepos: nil,
            followers: nil,
            following: nil
        )
    }

    override func tearDown() {
        user = nil
        coordinator = nil
        super.tearDown()
    }

    func testPopRemovesMostRecentRoute() {
        coordinator.showDetail(for: user)
        coordinator.showDetail(for: user)

        coordinator.pop()

        XCTAssertEqual(coordinator.navigationPath.count, 1)
    }

    func testPopDoesNothingWhenNavigationPathIsEmpty() {
        XCTAssertTrue(coordinator.navigationPath.isEmpty)

        coordinator.pop()

        XCTAssertTrue(coordinator.navigationPath.isEmpty)
    }

    func testViewFactoriesCanBuildTheirViews() {
        let startView = coordinator.buildStartView()
        XCTAssertNotNil(startView, "startView could not be created")

        let destinationView = coordinator.buildDestinationView(for: .detail(user: user))
        XCTAssertNotNil(destinationView, "destinationView could not be created")
    }
}

@MainActor
final class ModelAndUtilityTests: XCTestCase {
    func testGitHubUserDecodesSnakeCaseFields() throws {
        let data = Data(
            """
            {
              "id": 42,
              "login": "octocat",
              "avatar_url": "avatar",
              "html_url": "profile",
              "name": "The Octocat",
              "bio": "Mascot",
              "public_repos": 8,
              "followers": 10,
              "following": 2
            }
            """.utf8
        )

        let user = try JSONDecoder().decode(GitHubUser.self, from: data)

        XCTAssertEqual(user.id, 42)
        XCTAssertEqual(user.avatarUrl, "avatar")
        XCTAssertEqual(user.htmlUrl, "profile")
        XCTAssertEqual(user.publicRepos, 8)
        XCTAssertEqual(user.followers, 10)
        XCTAssertEqual(user.following, 2)
    }

    func testGitHubUserEncodesSnakeCaseFields() throws {
        let user = GitHubUser(
            id: 42,
            login: "octocat",
            avatarUrl: "avatar",
            htmlUrl: "profile",
            name: nil,
            bio: nil,
            publicRepos: 8,
            followers: nil,
            following: nil
        )

        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(user)) as? [String: Any]
        )

        XCTAssertEqual(object["avatar_url"] as? String, "avatar")
        XCTAssertEqual(object["html_url"] as? String, "profile")
        XCTAssertEqual(object["public_repos"] as? Int, 8)
    }

    func testNetworkErrorDescriptions() {
        XCTAssertEqual(NetworkError.invalidURL.errorDescription, "Invalid API endpoint.")
        XCTAssertEqual(NetworkError.serverError(statusCode: 404).errorDescription, "Server responded with code: 404.")
        XCTAssertEqual(NetworkError.parsingError.errorDescription, "Failed to parse data.")
        XCTAssertEqual(NetworkError.connectivityIssue("Offline").errorDescription, "Offline")
    }

    func testJailbreakDetectorReturnsFalseOnSimulator() {
        XCTAssertFalse(JailbreakDetector().isJailbroken())
    }
}

@MainActor
final class ViewConstructionTests: XCTestCase {
    func testUserDetailViewBuildsProfileContent() {
        let user = GitHubUser(
            id: 1,
            login: "octocat",
            avatarUrl: nil,
            htmlUrl: "https://github.com/octocat",
            name: "The Octocat",
            bio: "GitHub mascot",
            publicRepos: 8,
            followers: 10,
            following: 2
        )
        let viewModel = UserDetailViewModel(
            user: user,
            userService: StaticUserService(user: user)
        )

        let view = UserDetailView(viewModel: viewModel)
        _ = view.body
        host(view)
    }

    func testUserDetailViewBuildsProfileWithMissingOptionalValues() {
        let user = GitHubUser(
            id: 2,
            login: "minimal-user",
            avatarUrl: nil,
            htmlUrl: nil,
            name: nil,
            bio: "   ",
            publicRepos: nil,
            followers: nil,
            following: nil
        )
        let viewModel = UserDetailViewModel(
            user: user,
            userService: StaticUserService(user: user)
        )

        let view = UserDetailView(viewModel: viewModel)
        _ = view.body
        host(view)
    }

    func testUserListViewBuildsLoadedStateAndRows() async {
        let service = MockUserService()
        let viewModel = UserListViewModel(userService: service, coordinator: nil)
        await viewModel.loadUsers()

        let view = UserListView(
            viewModel: viewModel,
            networkMonitor: NetworkMonitor(),
            isJailbroken: true
        )
        _ = view.body
        host(view)
        _ = UserRowView(user: service.mockUsers[0]).body
    }

    func testUserListViewBuildsErrorState() async {
        let service = MockUserService()
        service.shouldFail = true
        let viewModel = UserListViewModel(userService: service, coordinator: nil)
        await viewModel.loadUsers()

        let view = UserListView(
            viewModel: viewModel,
            networkMonitor: NetworkMonitor(),
            isJailbroken: false
        )
        _ = view.body
        host(view)
    }

    func testReusableComponentsBuildTheirBodies() {
        _ = OfflineBannerView().body
        _ = JailbreakAlertView().body
        _ = MetricView(title: "Followers", value: "10", icon: "person.2").body
    }

    private func host<Content: View>(_ content: Content) {
        let controller = UIHostingController(rootView: content)
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        XCTAssertNotNil(controller.view)
    }
}

private final class StubURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (URLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let requestHandler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try requestHandler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

@MainActor
private final class RecordingAPIClient: APIClientProtocol {
    var responseData = Data()
    var error: Error?
    private(set) var requestedURL: URL?

    func request<T: Decodable>(url: URL) async throws -> T {
        requestedURL = url
        if let error {
            throw error
        }
        return try JSONDecoder().decode(T.self, from: responseData)
    }
}

private struct StubJailbreakDetector: JailbreakDetecting {
    func isJailbroken() -> Bool {
        false
    }
}

@MainActor
private struct StaticUserService: UserServiceProtocol {
    let user: GitHubUser

    func fetchUsers() async throws -> [GitHubUser] {
        [user]
    }

    func fetchUserDetails(username: String) async throws -> GitHubUser {
        user
    }
}
