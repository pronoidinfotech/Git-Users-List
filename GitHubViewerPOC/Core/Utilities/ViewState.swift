//
//  ViewState.swift
//  GitHubViewerPOC
//
//  Created by pradnya Kharche on 11/10/26.
//
import Foundation

enum ViewState<T: Equatable>: Equatable {
    case idle
    case loading
    case loaded(T)
    case error(String)
}
