import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage("onboardingDone")   private var onboardingDone  = false
    @AppStorage("accent")           private var accentRaw       = AccentColor.emerald.rawValue
    @AppStorage("showArabic")       private var showArabic      = true
    @AppStorage("trackingStart")    private var trackingStart   = makeDayKey()
    @AppStorage("locationName")     private var locationName    = "Your City"
    @AppStorage("remindersEnabled") private var remindersEnabled = true

    private var accent: AccentColor { AccentColor(rawValue: accentRaw) ?? .emerald }
    private var T: AppTheme { AppTheme.make(dark: colorScheme == .dark, accent: accent) }

    var body: some View {
        if !onboardingDone {
            OnboardingView(
                T: T,
                trackingStart: $trackingStart,
                locationName: $locationName,
                remindersEnabled: $remindersEnabled
            ) { onboardingDone = true }
        } else {
            TabView {
                HomeTab(T: T, showArabic: showArabic)
                    .tabItem { Label("Home", systemImage: "house.fill") }

                AnalyticsTab(T: T, trackingStart: trackingStart)
                    .tabItem { Label("Analytics", systemImage: "chart.bar.fill") }

                SettingsTab(
                    T: T,
                    trackingStart: $trackingStart,
                    locationName: $locationName,
                    remindersEnabled: $remindersEnabled,
                    accentRaw: $accentRaw,
                    showArabic: $showArabic
                )
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            }
            .tint(T.primary)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: PrayerEntry.self, inMemory: true)
}
