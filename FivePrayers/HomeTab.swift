import SwiftUI
import SwiftData
import Combine
import UIKit

struct HomeTab: View {
    let T: AppTheme
    let showArabic: Bool
    @ObservedObject var prayerTimeCache: PrayerTimeCache

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [PrayerEntry]

    @State private var bloomingId: String? = nil
    @State private var entered = false
    @State private var now = Date()

    private let clockTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var prayerTimeZone: TimeZone? {
        prayerTimeCache.selectedLocation.flatMap { TimeZone(identifier: $0.timezone) }
    }
    private var todayKey: String { PrayerTimeCache.dateKey(for: now, timezone: prayerTimeZone) }
    private var todayEntries: [PrayerEntry] { allEntries.filter { $0.dayKey == todayKey } }
    private var nowMin: Int { minutesSinceMidnight(now, timezone: prayerTimeZone) }

    private var todayPrayerTimes: DailyPrayerTimes? { prayerTimeCache.prayerTimes(for: now) }
    private var todaysPrayers: [Prayer] { Prayer.dailyPrayers(from: todayPrayerTimes) }
    private var prayerStates: [PrayerViewModel] { decoratePrayers(prayers: todaysPrayers, entries: todayEntries, nowMin: nowMin) }
    private var prayedCount: Int { prayerStates.filter(\.isPrayed).count }

    private var footerText: String {
        if prayerTimeCache.isDownloading { return "Downloading prayer times…" }
        if let loc = prayerTimeCache.selectedLocation {
            return "Times downloaded for \(loc.city), \(loc.country)."
        }
        return "Using fallback prayer times. Choose your city in Settings."
    }

    private var encourageText: String {
        let remaining = prayerStates.count - prayedCount
        if prayedCount == 5 { return "All five, done. Beautiful." }
        if prayedCount == 0 { return "A new day — one prayer at a time." }
        if remaining == 1   { return "Just one more to go. You're nearly there." }
        return "\(prayedCount) prayed · \(remaining) to go"
    }

    private var hijriDate: String {
        var cal = Calendar(identifier: .islamicCivil)
        cal.locale = Locale(identifier: "en")
        if let prayerTimeZone { cal.timeZone = prayerTimeZone }
        let c = cal.dateComponents([.month, .day], from: now)
        let months = ["Muharram","Safar","Rabi\u{2018} al-Awwal","Rabi\u{2018} al-Thani",
                      "Jumada al-Awwal","Jumada al-Thani","Rajab","Sha\u{2018}ban",
                      "Ramadan","Shawwal","Dhul Qa\u{2018}dah","Dhul Hijjah"]
        let m = max(1, min(12, c.month ?? 1))
        return "\(c.day ?? 1) \(months[m - 1])"
    }

    private var gregorianDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        fmt.timeZone = prayerTimeZone ?? TimeZone.current
        return fmt.string(from: now)
    }

    var body: some View {
        ZStack {
            T.page.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    HeaderView(T: T, hijri: hijriDate, greg: gregorianDate)

                    HeroView(rows: prayerStates, T: T, now: now, timeZone: prayerTimeZone,
                             blooming: bloomingId, onMark: toggle)
                        .padding(.top, 18)

                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("Today's prayers")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(T.text)
                            .kerning(-0.2)
                        Spacer()
                        Text(encourageText)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(T.muted)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.horizontal, 4)
                    .padding(.top, 24)
                    .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        ForEach(Array(prayerStates.enumerated()), id: \.element.id) { i, row in
                            PrayerRowView(
                                row: row, T: T,
                                blooming: bloomingId == row.id,
                                showArabic: showArabic,
                                delay: Double(i) * 0.055,
                                animate: !entered,
                                onToggle: { toggle(row.id) }
                            )
                        }
                    }

                    Text(footerText)
                        .font(.system(size: 12.5))
                        .foregroundStyle(T.faint)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.top, 22)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .onAppear {
            now = Date()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { entered = true }
        }
        .onReceive(clockTimer) { tick in now = tick }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            now = Date()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { now = Date() }
        }
    }

    private func toggle(_ id: String) {
        if let existing = todayEntries.first(where: { $0.prayerId == id }) {
            modelContext.delete(existing)
        } else {
            let isMissed: Bool
            if case .missed = prayerStates.first(where: { $0.id == id })?.display {
                isMissed = true
            } else {
                isMissed = false
            }
            modelContext.insert(PrayerEntry(dayKey: todayKey, prayerId: id, madeUp: isMissed))
            bloomingId = id
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) { bloomingId = nil }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
}
