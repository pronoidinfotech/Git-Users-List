//
//  GitHubUser.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation

struct GitHubUser: Codable, Identifiable, Hashable, Equatable {
    let id: Int
    let login: String
    let avatarUrl: String?
    let htmlUrl: String?
    let name: String?
    let bio: String?
    let publicRepos: Int?
    let followers: Int?
    let following: Int?

    enum CodingKeys: String, CodingKey {
        case id, login, name, bio
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case publicRepos = "public_repos"
        case followers, following
    }
}
