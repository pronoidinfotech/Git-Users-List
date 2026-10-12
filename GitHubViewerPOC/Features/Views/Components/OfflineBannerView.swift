//
//  OfflineBannerView.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation
import SwiftUI

struct OfflineBannerView: View {
    var body: some View {
        Text("No Internet Connection")
            .font(.caption.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(6)
            .background(Color.red)
    }
}

