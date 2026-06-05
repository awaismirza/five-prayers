import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query private var allEntries: [PrayerEntry]

    @State private var bloomingId: String? = nil
    @State private var entered = false
    @State private var tick = Date()

    private let minuteTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    private var T: AppTheme { AppTheme.make(dark: colorScheme == .dark) }

    private var todayKey: String { makeDayKey() }

    private var todayEntries: [PrayerEntry] {
        allEntries.filter { $0.dayKey == todayKey }
    }

    private var nowMin: Int { currentMinutes() }

    private var prayerStates: [PrayerViewModel] {
        decoratePrayers(entries: todayEntries, nowMin: nowMin)
    }

    private var prayedCount: Int { prayerStates.filter(\.isPrayed).count }

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
        let c = cal.dateComponents([.month, .day], from: Date())
        let months = ["Muharram","Safar","Rabi\u{2018} al-Awwal","Rabi\u{2018} al-Thani",
                      "Jumada al-Awwal","Jumada al-Thani","Rajab","Sha\u{2018}ban",
                      "Ramadan","Shawwal","Dhul Qa\u{2018}dah","Dhul Hijjah"]
        let m = max(1, min(12, c.month ?? 1))
        return "\(c.day ?? 1) \(months[m - 1])"
    }

    private var gregorianDate: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMMM yyyy"
        return fmt.string(from: Date())
    }

    var body: some View {
        ZStack {
            T.page.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    HeaderView(T: T, hijri: hijriDate, greg: gregorianDate)

                    HeroView(
                        rows: prayerStates, T: T, nowMin: nowMin,
                        blooming: bloomingId, onMark: toggle
                    )
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
                                row: row,
                                T: T,
                                blooming: bloomingId == row.id,
                                showArabic: true,
                                delay: Double(i) * 0.055,
                                animate: !entered,
                                onToggle: { toggle(row.id) }
                            )
                        }
                    }

                    Text("Tap any prayer to log it. Times shown for your location.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(T.faint)
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                        .padding(.top, 22)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 56)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { entered = true }
        }
        .onReceive(minuteTimer) { _ in tick = Date() }
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

#Preview {
    ContentView()
        .modelContainer(for: PrayerEntry.self, inMemory: true)
}
