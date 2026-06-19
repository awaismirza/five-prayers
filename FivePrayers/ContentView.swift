import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("onboardingDone")   private var onboardingDone  = false
    @AppStorage("accent")           private var accentRaw       = AccentColor.emerald.rawValue
    @AppStorage("showArabic")       private var showArabic      = true
    @AppStorage("trackingStart")    private var trackingStart   = makeDayKey()
    @AppStorage("locationName")     private var locationName    = "Your City"
    @AppStorage("remindersEnabled") private var remindersEnabled = true

    @StateObject private var citySearchService = CitySearchService()
    @StateObject private var prayerTimeCache   = PrayerTimeCache()

    private var accent: AccentColor { AccentColor(rawValue: accentRaw) ?? .emerald }
    private var T: AppTheme { AppTheme.make(dark: colorScheme == .dark, accent: accent) }

    var body: some View {
        if !onboardingDone {
            OnboardingView(
                T: T,
                trackingStart: $trackingStart,
                locationName: $locationName,
                remindersEnabled: $remindersEnabled,
                citySearchService: citySearchService,
                prayerTimeCache: prayerTimeCache
            ) { onboardingDone = true }
        } else {
            TabView {
                HomeTab(T: T, showArabic: showArabic, prayerTimeCache: prayerTimeCache)
                    .tabItem { Label("Home", systemImage: "house.fill") }

                AnalyticsTab(T: T, trackingStart: trackingStart, prayerTimeCache: prayerTimeCache)
                    .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

                SettingsTab(
                    T: T,
                    trackingStart: $trackingStart,
                    locationName: $locationName,
                    remindersEnabled: $remindersEnabled,
                    accentRaw: $accentRaw,
                    showArabic: $showArabic,
                    prayerTimeCache: prayerTimeCache,
                    citySearchService: citySearchService
                )
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(T.primary)
            .task {
                prayerTimeCache.load()
                await prayerTimeCache.checkAndRedownloadIfNeeded()
                await PrayerNotificationService.shared.refreshSchedule(
                    remindersEnabled: remindersEnabled,
                    prayerTimeCache: prayerTimeCache
                )
            }
            .onChange(of: scenePhase) { _, phase in
                guard phase == .active else { return }
                Task {
                    await PrayerNotificationService.shared.refreshSchedule(
                        remindersEnabled: remindersEnabled,
                        prayerTimeCache: prayerTimeCache
                    )
                }
            }
            .onChange(of: remindersEnabled) { _, enabled in
                Task {
                    await PrayerNotificationService.shared.refreshSchedule(
                        remindersEnabled: enabled,
                        prayerTimeCache: prayerTimeCache
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [PrayerEntry.self, MadeUpPrayerEntry.self], inMemory: true)
}
