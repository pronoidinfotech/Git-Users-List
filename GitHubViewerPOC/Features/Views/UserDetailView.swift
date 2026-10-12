//
//  UserDetailView.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import SwiftUI
struct UserDetailView: View {
    @StateObject var viewModel: UserDetailViewModel

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {

                // Profile Card
                VStack(spacing: 0) {

                    // Header
                    ZStack {
                        LinearGradient(
                            colors: [
                                Color(.darkGray),
                                Color(.black)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .frame(height: 110)

                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 42, weight: .light))
                            .foregroundStyle(.white.opacity(0.12))
                            .frame(
                                maxWidth: .infinity,
                                alignment: .trailing
                            )
                            .padding(.trailing, 24)
                    }

                    // Profile Information
                    VStack(spacing: 12) {

                        AsyncImage(
                            url: URL(
                                string: viewModel.user.avatarUrl ?? ""
                            )
                        ) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .scaledToFill()
                            } else if phase.error != nil {
                                avatarPlaceholder
                            } else {
                                ProgressView()
                            }
                        }
                        .frame(width: 104, height: 104)
                        .clipShape(Circle())
                        .padding(4)
                        .background {
                            Circle()
                                .fill(Color(uiColor: .secondarySystemBackground))
                        }
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    Color.primary.opacity(0.08),
                                    lineWidth: 1
                                )
                        }
                        .shadow(
                            color: .black.opacity(0.12),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                        .padding(.top, -54)

                        Text(
                            viewModel.user.name
                                ?? viewModel.user.login
                        )
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                        Text("@\(viewModel.user.login)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if let bio = viewModel.user.bio,
                           !bio.trimmingCharacters(
                               in: .whitespacesAndNewlines
                           ).isEmpty {
                            Text(bio)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.secondary)

                            Text("GitHub Developer")
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption.weight(.medium))
                        .padding(.top, 2)
                    }
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
                    .background(
                        Color(uiColor: .secondarySystemBackground)
                    )
                }
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay {
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            Color.primary.opacity(0.06),
                            lineWidth: 1
                        )
                }
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 14,
                    x: 0,
                    y: 6
                )

                // Statistics
                HStack(spacing: 12) {
                    MetricView(
                        title: "Repositories",
                        value: "\(viewModel.user.publicRepos ?? 0)",
                        icon: "book.closed"
                    )

                    MetricView(
                        title: "Followers",
                        value: "\(viewModel.user.followers ?? 0)",
                        icon: "person.2"
                    )

                    MetricView(
                        title: "Following",
                        value: "\(viewModel.user.following ?? 0)",
                        icon: "person.crop.circle.badge.plus"
                    )
                }

                // GitHub Profile Button
                if let urlString = viewModel.user.htmlUrl,
                   let url = URL(string: urlString),
                   url.scheme == "https",
                   url.host == "github.com" {

                    Link(destination: url) {
                        HStack(spacing: 10) {
                            Image(systemName: "arrow.up.right.square")

                            Text("View GitHub Profile")
                                .fontWeight(.semibold)

                            Spacer()

                            Image(systemName: "arrow.right")
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .padding(18)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadUserDetails()
        }
    }

    private var avatarPlaceholder: some View {
        Image(systemName: "person.crop.circle.fill")
            .resizable()
            .scaledToFit()
            .foregroundStyle(.secondary)
            .padding(12)
            .background(Color(uiColor: .tertiarySystemBackground))
    }
}

// MARK: - Metric Card

struct MetricView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 10) {

            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.secondary)
            

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 5)
        .background(Color.gray.opacity(0.06)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    Color.primary.opacity(0.08),
                    lineWidth: 2
                )
        }
        .shadow(
            color: .black.opacity(0.06),
            radius: 6,
            x: 0,
            y: 3
        )
    }
}
