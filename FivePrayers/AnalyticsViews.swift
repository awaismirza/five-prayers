import SwiftUI
import SwiftData

struct AnalyticsTab: View {
    let T: AppTheme
    let trackingStart: String

    @Query private var allEntries: [PrayerEntry]

    private var stats: PrayerStats {
        computeStats(entries: allEntries, trackingStart: trackingStart)
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

                    // Header
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Your journey")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(T.muted)
                        Text("Tracking since \(sinceLabel)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(T.text)
                            .kerning(-0.4)
                        Text(stats.daysTracked == 1 ? "today" : "\(stats.daysTracked) days")
                            .font(.system(size: 13))
                            .foregroundStyle(T.faint)
                            .padding(.top, 2)
                    }
                    .padding(.bottom, 20)

                    // Big stat cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        StatCard(T: T, label: "Current Streak",
                                 value: stats.currentStreak, unit: "days",
                                 icon: "flame.fill", iconColor: .orange)
                        StatCard(T: T, label: "Longest Streak",
                                 value: stats.longestStreak, unit: "days",
                                 icon: "star.fill", iconColor: Color(hex: "E2B92C"))
                        StatCard(T: T, label: "Completion",
                                 value: stats.completionRate, unit: "%",
                                 icon: "checkmark.circle.fill", iconColor: T.prayed)
                        StatCard(T: T, label: "On-Time",
                                 value: stats.onTimeRate, unit: "%",
                                 icon: "clock.fill", iconColor: T.primary)
                    }
                    .padding(.bottom, 28)

                    // Per-prayer consistency
                    Text("Consistency by prayer")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(T.text)
                        .kerning(-0.2)
                        .padding(.bottom, 12)

                    VStack(spacing: 10) {
                        ForEach(Prayer.all) { prayer in
                            let stat = stats.byPrayer[prayer.id]
                                ?? PrayerPrayerStat(logged: 0, onTime: 0, madeUp: 0)
                            PrayerBreakdownRow(prayer: prayer, stat: stat, T: T)
                        }
                    }
                    .padding(.bottom, 28)

                    // On-time vs made-up
                    Text("Breakdown")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(T.text)
                        .kerning(-0.2)
                        .padding(.bottom, 12)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        BreakdownCard(T: T, label: "On-time",
                                      value: stats.totalOnTime, color: T.prayed)
                        BreakdownCard(T: T, label: "Made up",
                                      value: stats.totalMadeUp, color: T.amber)
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

struct PrayerBreakdownRow: View {
    let prayer: Prayer
    let stat: PrayerPrayerStat
    let T: AppTheme

    private var barColor: Color {
        stat.onTimeRate >= 80 ? T.prayed
        : stat.onTimeRate >= 50 ? T.amber
        : Color(hex: "E06767")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(prayer.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(T.text)
                Spacer()
                Text(stat.madeUp > 0
                     ? "\(stat.logged) logged (\(stat.madeUp) made up)"
                     : "\(stat.logged) logged")
                    .font(.system(size: 12))
                    .foregroundStyle(T.muted)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(T.cardSub).frame(height: 6)
                    Capsule().fill(barColor)
                        .frame(
                            width: max(
                                CGFloat(stat.onTimeRate) / 100.0 * geo.size.width,
                                stat.logged > 0 ? 8 : 0
                            ),
                            height: 6
                        )
                        .animation(.easeOut(duration: 0.4), value: stat.onTimeRate)
                }
            }
            .frame(height: 6)
            Text("\(stat.onTimeRate)% on-time")
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
