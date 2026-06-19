import SwiftUI
import SwiftData
import Combine

struct AnalyticsTab: View {
    let T: AppTheme
    let trackingStart: String
    @ObservedObject var prayerTimeCache: PrayerTimeCache

    @Environment(\.modelContext) private var modelContext
    @Query private var allEntries: [PrayerEntry]
    @Query private var madeUpEntries: [MadeUpPrayerEntry]
    @State private var now = Date()
    @State private var selectedPrayer: Prayer? = nil

    private let clockTimer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var prayerTimeZone: TimeZone? {
        prayerTimeCache.selectedLocation.flatMap { TimeZone(identifier: $0.timezone) }
    }

    private var todayPrayers: [Prayer] {
        Prayer.dailyPrayers(from: prayerTimeCache.prayerTimes(for: now))
    }

    private var stats: PrayerStats {
        computeStats(
            entries: allEntries,
            madeUpEntries: madeUpEntries,
            trackingStart: trackingStart,
            todayPrayers: todayPrayers,
            now: now,
            timezone: prayerTimeZone
        )
    }

    private var remainingMissed: [MissedPrayerInstance] {
        remainingMissedPrayerInstances(
            entries: allEntries,
            madeUpEntries: madeUpEntries,
            trackingStart: trackingStart,
            todayPrayers: todayPrayers,
            now: now,
            timezone: prayerTimeZone
        )
    }

    private var sinceLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: trackingStart) else { return trackingStart }
        let disp = DateFormatter()
        disp.dateFormat = "MMM d"
        return disp.string(from: date)
    }

    var body: some View {
        ZStack {
            T.page.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Your journey")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(T.muted)
                        Text("Progress")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(T.text)
                            .kerning(-0.4)
                        Text("Tracking since \(sinceLabel) · \(stats.daysTracked == 1 ? "today" : "\(stats.daysTracked) days")")
                            .font(.system(size: 13))
                            .foregroundStyle(T.faint)
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 20)

                    ProgressSummaryCard(T: T, stats: stats)
                        .padding(.bottom, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(T: T, label: "Current Streak",
                                 value: stats.currentStreak, unit: "days",
                                 icon: "flame.fill", iconColor: .orange)
                        StatCard(T: T, label: "Longest Streak",
                                 value: stats.longestStreak, unit: "days",
                                 icon: "star.fill", iconColor: Color(hex: "E2B92C"))
                        StatCard(T: T, label: "Prayed Rate",
                                 value: stats.completionRate, unit: "%",
                                 icon: "checkmark.circle.fill", iconColor: T.prayed)
                        StatCard(T: T, label: "Prayed",
                                 value: stats.totalPrayed, unit: "total",
                                 icon: "hands.sparkles.fill", iconColor: T.primary)
                    }
                    .padding(.bottom, 28)

                    Text("Missed prayers by prayer")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(T.text)
                        .kerning(-0.2)
                        .padding(.bottom, 12)

                    if stats.totalRemainingMissed == 0 {
                        ProgressEmptyCard(T: T)
                            .padding(.bottom, 28)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(Prayer.all) { prayer in
                                let stat = stats.byPrayer[prayer.id]
                                    ?? PrayerPrayerStat(expected: 0, prayed: 0, missedOriginal: 0, onTime: 0, madeUp: 0, remainingMissed: 0)
                                ProgressPrayerRow(prayer: prayer, stat: stat, T: T) {
                                    if stat.remainingMissed > 0 { selectedPrayer = prayer }
                                }
                            }
                        }
                        .padding(.bottom, 28)
                    }

                    Text("Breakdown")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(T.text)
                        .kerning(-0.2)
                        .padding(.bottom, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BreakdownCard(T: T, label: "Made Up",
                                      value: stats.totalMadeUp, color: T.prayed)
                        BreakdownCard(T: T, label: "Total Missed",
                                      value: stats.totalMissedOriginal, color: T.amber)
                    }
                    .padding(.bottom, 22)

                    Text("Keep it consistent. Every prayer counts.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(T.faint)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
        .onAppear { now = Date() }
        .onReceive(clockTimer) { tick in now = tick }
        .sheet(item: $selectedPrayer) { prayer in
            MadeUpPrayerSheet(
                prayer: prayer,
                instances: remainingMissed.filter { $0.prayerId == prayer.id },
                stat: stats.byPrayer[prayer.id]
                    ?? PrayerPrayerStat(expected: 0, prayed: 0, missedOriginal: 0, onTime: 0, madeUp: 0, remainingMissed: 0),
                T: T,
                madeUpEntries: madeUpEntries,
                onMarkMadeUp: markMadeUp
            )
            .presentationDetents([.medium, .large])
        }
    }

    private func markMadeUp(_ instance: MissedPrayerInstance) {
        let key = missedInstanceKey(dayKey: instance.dayKey, prayerId: instance.prayerId)
        let alreadyMadeUp = madeUpEntries.contains {
            missedInstanceKey(dayKey: $0.originalDayKey, prayerId: $0.prayerId) == key
        }
        guard !alreadyMadeUp else { return }

        modelContext.insert(
            MadeUpPrayerEntry(
                prayerId: instance.prayerId,
                prayerName: instance.prayerName,
                originalDayKey: instance.dayKey,
                originalDate: instance.date,
                madeUpAt: Date()
            )
        )
        try? modelContext.save()
    }
}

// MARK: - Progress summary card

struct ProgressSummaryCard: View {
    let T: AppTheme
    let stats: PrayerStats

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(stats.totalRemainingMissed == 0 ? T.prayed : T.amber)
                    .frame(width: 38)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Remaining Missed")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(T.muted)
                    Text("\(stats.totalRemainingMissed) prayers")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(T.text)
                        .monospacedDigit()
                    Text("Made Up: \(stats.totalMadeUp) · Total missed: \(stats.totalMissedOriginal)")
                        .font(.system(size: 12.5))
                        .foregroundStyle(T.faint)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(T.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(T.line, lineWidth: 1))
        .shadow(color: T.dark ? .black.opacity(0.24) : .black.opacity(0.08),
            radius: 16, x: 0, y: 10)
    }
}

struct ProgressEmptyCard: View {
    let T: AppTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .font(.system(size: 21))
                    .foregroundStyle(T.prayed)
                Text("No remaining missed prayers.")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(T.text)
            }
            Text("May Allah keep you consistent.")
                .font(.system(size: 13))
                .foregroundStyle(T.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(T.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
        .shadow(color: T.dark ? .black.opacity(0.24) : .black.opacity(0.08),
            radius: 16, x: 0, y: 10)
    }
}

// MARK: - Stat card

struct StatCard: View {
    let T: AppTheme
    let label: String
    let value: Int
    let unit: String
    let icon: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(T.muted)
                    .lineLimit(1)
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(value)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(T.text)
                        .kerning(-0.3)
                    Text(unit)
                        .font(.system(size: 12))
                        .foregroundStyle(T.faint)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(T.card)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(T.line, lineWidth: 1))
        .shadow(color: T.dark ? .black.opacity(0.24) : .black.opacity(0.08),
            radius: 16, x: 0, y: 10)
    }
}

// MARK: - Prayer breakdown row

struct ProgressPrayerRow: View {
    let prayer: Prayer
    let stat: PrayerPrayerStat
    let T: AppTheme
    let onTap: () -> Void

    private var barColor: Color {
        stat.completionRate >= 80 ? T.prayed
        : stat.completionRate >= 50 ? T.amber
        : Color(hex: "E06767")
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(prayer.name)
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(T.text)
                        Text("Remaining missed: \(stat.remainingMissed)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(stat.remainingMissed > 0 ? T.amberOn : T.muted)
                    }
                    Spacer()
                    if stat.remainingMissed > 0 {
                        Text("Make Up")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(T.onPrimary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(T.primary)
                            .clipShape(Capsule())
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(T.cardSub).frame(height: 6)
                        Capsule().fill(barColor)
                            .frame(
                                width: max(
                                    CGFloat(stat.completionRate) / 100.0 * geo.size.width,
                                    stat.prayed > 0 ? 8 : 0
                                ),
                                height: 6
                            )
                            .animation(.easeOut(duration: 0.4), value: stat.completionRate)
                    }
                }
                .frame(height: 6)

                HStack(spacing: 6) {
                    Text("Prayed: \(stat.prayed)")
                    Text("· Made Up: \(stat.madeUp)")
                    Text("· Total missed: \(stat.missedOriginal)")
                }
                .font(.system(size: 12))
                .foregroundStyle(T.faint)
            }
            .padding(14)
            .background(T.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
            .shadow(color: T.dark ? .black.opacity(0.24) : .black.opacity(0.08),
                radius: 16, x: 0, y: 10)
        }
        .buttonStyle(ScaleButtonStyle(scale: stat.remainingMissed > 0 ? 0.985 : 1))
        .disabled(stat.remainingMissed == 0)
    }
}

// MARK: - Breakdown card

struct BreakdownCard: View {
    let T: AppTheme
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(T.muted)
            Text("\(value)")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(color)
                .kerning(-0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(T.card)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(T.line, lineWidth: 1))
        .shadow(color: T.dark ? .black.opacity(0.24) : .black.opacity(0.08),
            radius: 16, x: 0, y: 10)
    }
}
