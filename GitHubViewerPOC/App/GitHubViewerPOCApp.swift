//
//  GitHubViewerPOCApp.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import SwiftUI
import Foundation
@main
struct GitHubViewerPOCApp: App {
    @StateObject private var coordinator = AppCoordinator()

        var body: some Scene {
            WindowGroup {
                NavigationStack(path: $coordinator.navigationPath) {
                    coordinator.buildStartView()
                        .navigationDestination(for: AppRoute.self) { route in
                            coordinator.buildDestinationView(for: route)
                        }
                }
            }
        }
    }
