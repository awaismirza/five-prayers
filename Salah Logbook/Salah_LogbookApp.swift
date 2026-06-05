//
//  Salah_LogbookApp.swift
//  Salah Logbook
//
//  Created by mohr on 5/6/2026.
//

import SwiftUI
import SwiftData

@main
struct Salah_LogbookApp: App {
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

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
