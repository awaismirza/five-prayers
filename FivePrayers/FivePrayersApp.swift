//
//  FivePrayersApp.swift
//  Five Prayers
//
//  Created by mohr on 5/6/2026.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct FivePrayersApp: App {
    private let notificationDelegate = AppNotificationDelegate()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            PrayerEntry.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
