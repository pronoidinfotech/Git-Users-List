//
//  Endpoint.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation

enum NetworkError: LocalizedError, Equatable {
    case invalidURL
    case serverError(statusCode: Int)
    case parsingError
    case connectivityIssue(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API endpoint."
        case .serverError(let code): return "Server responded with code: \(code)."
        case .parsingError: return "Failed to parse data."
        case .connectivityIssue(let message): return message
        }
    }
}

protocol APIClientProtocol {
    func request<T: Decodable>(url: URL) async throws -> T
}

final class APIClient: APIClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(url: URL) async throws -> T {
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw NetworkError.connectivityIssue(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.parsingError
        }
    }
}
