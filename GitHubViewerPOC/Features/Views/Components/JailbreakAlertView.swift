//
//  JailbreakAlertView.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//
import SwiftUI
import Foundation


struct JailbreakAlertView: View {
    var body: some View {
        Text("⚠️ Security Warning: Device integrity compromised.")
            .font(.caption.bold())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(6)
            .background(Color.orange)
    }
}
