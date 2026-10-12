//
//  UserListView.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import SwiftUI

struct UserListView: View {
    @StateObject var viewModel: UserListViewModel
    @ObservedObject var networkMonitor: NetworkMonitor
    let isJailbroken: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                OfflineBannerView()
            }
            if isJailbroken {
                JailbreakAlertView()
            }

            contentView
        }
        .navigationTitle("Github Users")
        .task {
            if case .idle = viewModel.state {
                await viewModel.loadUsers()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView("Loading...").frame(maxHeight: .infinity)
        case .error(let message):
            VStack(spacing: 12) {
                Text(message).foregroundColor(.red)
                Button("Retry") { Task { await viewModel.loadUsers() } }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxHeight: .infinity)
        case .loaded(let users):
            List(users) { user in
                Button {
                    viewModel.didSelectUser(user)
                } label: {
                    UserRowView(user: user)
                }
                .buttonStyle(.plain)
            }
            .refreshable {
                await viewModel.loadUsers()
            }
        }
    }
}

struct UserRowView: View {
    let user: GitHubUser

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user.avatarUrl ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.crop.circle.fill").resizable()
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())

            Text(user.login)
                .font(.headline)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

