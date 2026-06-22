import Foundation
import UIKit
import Combine

enum AppUpdateAlertType: Identifiable {
    case updateAvailable(version: String, url: URL?)
    case noUpdate(currentVersion: String)
    case checkFailed(message: String)
    
    var id: String {
        switch self {
        case .updateAvailable(let version, _):
            return "update-\(version)"
        case .noUpdate(let version):
            return "noupdate-\(version)"
        case .checkFailed(let msg):
            return "failed-\(msg)"
        }
    }
}

@MainActor
class AppUpdateService: ObservableObject {
    static let shared = AppUpdateService()
    
    @Published var alertType: AppUpdateAlertType? = nil
    @Published var isChecking = false
    @Published var simulateUpdateAvailable = false
    
    private let lastCheckedKey = "AppUpdateService.lastCheckedDate"
    
    var lastCheckedText: String {
        guard let date = UserDefaults.standard.object(forKey: lastCheckedKey) as? Date else {
            return "Never checked"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Last checked: \(formatter.localizedString(for: date, relativeTo: Date()))"
    }
    
    func checkForUpdates(explicit: Bool) async {
        guard !isChecking else { return }
        isChecking = true
        
        // Brief sleep to show active feedback to the user on manual check
        if explicit {
            try? await Task.sleep(nanoseconds: 750_000_000)
        }
        
        defer {
            isChecking = false
            // Save check time for status string if check completed or found update
            UserDefaults.standard.set(Date(), forKey: lastCheckedKey)
            objectWillChange.send()
        }
        
        // Handle debug mocking
        if simulateUpdateAvailable {
            let mockURL = URL(string: "https://apps.apple.com/app/id1234567890")
            alertType = .updateAvailable(version: "2.0.0", url: mockURL)
            return
        }
        
        guard let bundleId = Bundle.main.bundleIdentifier else {
            if explicit {
                alertType = .checkFailed(message: "Could not read app bundle identifier.")
            }
            return
        }
        
        let urlString = "https://itunes.apple.com/lookup?bundleId=\(bundleId)"
        guard let url = URL(string: urlString) else {
            if explicit {
                alertType = .checkFailed(message: "Invalid URL generated for update check.")
            }
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            struct LookupResult: Codable {
                struct AppInfo: Codable {
                    let version: String?
                    let trackViewUrl: String?
                }
                let resultCount: Int
                let results: [AppInfo]
            }
            
            let response = try JSONDecoder().decode(LookupResult.self, from: data)
            let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1"
            
            if response.resultCount > 0, let appInfo = response.results.first, let appStoreVersion = appInfo.version {
                let trackURL = appInfo.trackViewUrl.flatMap { URL(string: $0) }
                if appStoreVersion.compare(currentVersion, options: .numeric) == .orderedDescending {
                    alertType = .updateAvailable(version: appStoreVersion, url: trackURL)
                } else {
                    if explicit {
                        alertType = .noUpdate(currentVersion: currentVersion)
                    }
                }
            } else {
                // If it returned 0 results (expected for an app not yet published or under development),
                // it means we're running latest or cannot check.
                if explicit {
                    alertType = .noUpdate(currentVersion: currentVersion)
                }
            }
        } catch {
            if explicit {
                alertType = .checkFailed(message: error.localizedDescription)
            }
        }
    }
}
