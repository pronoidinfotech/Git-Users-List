//
//  JailbreakDetector.swift
//  GitHubViewerPOC
//
//  Created by pradnya kharche on 08/10/26.
//

import Foundation
import UIKit

protocol JailbreakDetecting {
    func isJailbroken() -> Bool
}

final class JailbreakDetector: JailbreakDetecting {
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkSuspiciousPaths() || checkCanWriteToRestrictedDirectory() || checkCydiaScheme()
        #endif
    }

    private func checkSuspiciousPaths() -> Bool {
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt"
        ]
        return paths.contains { FileManager.default.fileExists(atPath: $0) }
    }

    private func checkCanWriteToRestrictedDirectory() -> Bool {
        let path = "/private/jailbreak_test_\(UUID().uuidString).txt"
        do {
            try "test".write(toFile: path, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    private func checkCydiaScheme() -> Bool {
        guard let url = URL(string: "cydia://package/com.poc.test") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
