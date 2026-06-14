import Foundation
import SwiftData
import SwiftUI

// MARK: - SwiftData model

@Model
final class PrayerEntry {
    var dayKey: String
    var prayerId: String
    var madeUp: Bool

    init(dayKey: String, prayerId: String, madeUp: Bool = false) {
        self.dayKey = dayKey
        self.prayerId = prayerId
        self.madeUp = madeUp
    }
}

// MARK: - Static prayer data

struct Prayer: Identifiable {
    let id: String
    let name: String
    let arabic: String
    let timeMinutes: Int

    static let fallback: [Prayer] = [
        Prayer(id: "fajr",    name: "Fajr",    arabic: "الفجر",  timeMinutes: 5  * 60 + 12),
        Prayer(id: "dhuhr",   name: "Dhuhr",   arabic: "الظهر",  timeMinutes: 13 * 60 + 4),
        Prayer(id: "asr",     name: "Asr",     arabic: "العصر",  timeMinutes: 16 * 60 + 42),
        Prayer(id: "maghrib", name: "Maghrib", arabic: "المغرب", timeMinutes: 19 * 60 + 58),
        Prayer(id: "isha",    name: "Isha",    arabic: "العشاء",  timeMinutes: 21 * 60 + 21),
    ]

    static var all: [Prayer] { fallback }

    static func dailyPrayers(from times: DailyPrayerTimes?) -> [Prayer] {
        guard let times else { return fallback }
        return [
            Prayer(id: "fajr",    name: "Fajr",    arabic: "الفجر",  timeMinutes: times.fajr),
            Prayer(id: "dhuhr",   name: "Dhuhr",   arabic: "الظهر",  timeMinutes: times.dhuhr),
            Prayer(id: "asr",     name: "Asr",     arabic: "العصر",  timeMinutes: times.asr),
            Prayer(id: "maghrib", name: "Maghrib", arabic: "المغرب", timeMinutes: times.maghrib),
            Prayer(id: "isha",    name: "Isha",    arabic: "العشاء",  timeMinutes: times.isha),
        ]
    }
}

// MARK: - Display state

enum PrayerDisplayState: Equatable {
    case prayed(madeUp: Bool)
    case now
    case missed
    case upcoming
}

struct PrayerViewModel: Identifiable {
    let prayer: Prayer
    let display: PrayerDisplayState
    var id: String { prayer.id }
    var isPrayed: Bool { if case .prayed = display { true } else { false } }
}

// MARK: - Accent color

enum AccentColor: String, CaseIterable {
    case emerald, teal, pine
    var label: String {
        switch self {
        case .emerald: return "Emerald"
        case .teal:    return "Teal"
        case .pine:    return "Pine"
        }
    }
}

// MARK: - Theme

struct AppTheme {
    let dark: Bool
    let page: Color
    let card: Color
    let cardSub: Color
    let line: Color
    let primary: Color
    let primaryDeep: Color
    let onPrimary: Color
    let heroFrom: Color
    let heroTo: Color
    let prayed: Color
    let prayedSoft: Color
    let prayedOn: Color
    let amber: Color
    let amberSoft: Color
    let amberOn: Color
    let text: Color
    let muted: Color
    let faint: Color
    let idleRing: Color

    static func make(dark: Bool, accent: AccentColor = .emerald) -> AppTheme {
        struct Pal { let lp, ld, dp, dd: String }
        let pal: Pal
        switch accent {
        case .emerald: pal = Pal(lp: "0F7A66", ld: "0B5B4D", dp: "44D0AA", dd: "0D2A24")
        case .teal:    pal = Pal(lp: "117A8B", ld: "0B5561", dp: "53C9DB", dd: "0D2830")
        case .pine:    pal = Pal(lp: "2E6B57", ld: "214B3E", dp: "66C6A1", dd: "12241E")
        }
        if !dark {
            return AppTheme(
                dark: false, page: Color(hex: "F4F5F7"), card: Color.white,
                cardSub: Color(hex: "EEF1F4"), line: Color.black.opacity(0.07),
                primary: Color(hex: pal.lp), primaryDeep: Color(hex: pal.ld), onPrimary: .white,
                heroFrom: Color(hex: pal.lp), heroTo: Color(hex: pal.ld),
                prayed: Color(hex: "1E9E64"), prayedSoft: Color(hex: "EDF8F2"), prayedOn: Color(hex: "16784A"),
                amber: Color(hex: "D48A1F"), amberSoft: Color(hex: "FFF5E8"), amberOn: Color(hex: "9A6210"),
                text: Color(hex: "111315"), muted: Color(hex: "66707A"),
                faint: Color(hex: "9AA3AD"), idleRing: Color(hex: "D7DDE3")
            )
        }
        return AppTheme(
            dark: true, page: Color(hex: "090A0B"), card: Color(hex: "15171A"),
            cardSub: Color(hex: "1C1F23"), line: Color.white.opacity(0.08),
            primary: Color(hex: pal.dp), primaryDeep: Color(hex: pal.dd), onPrimary: Color(hex: "07120F"),
            heroFrom: Color(hex: "14181B"), heroTo: Color(hex: "0B0C0E"),
            prayed: Color(hex: "63D398"), prayedSoft: Color(hex: "63D398").opacity(0.14), prayedOn: Color(hex: "89E0B4"),
            amber: Color(hex: "F0B252"), amberSoft: Color(hex: "F0B252").opacity(0.14), amberOn: Color(hex: "F7C36F"),
            text: Color(hex: "F4F5F6"), muted: Color(hex: "95A0AA"),
            faint: Color(hex: "69727C"), idleRing: Color(hex: "353A41")
        )
    }

    static let lightTheme = make(dark: false)
    static let darkTheme  = make(dark: true)
}

// MARK: - Analytics stats

struct PrayerPrayerStat {
    let logged: Int
    let onTime: Int
    let madeUp: Int
    var onTimeRate: Int { logged > 0 ? Int(Double(onTime) / Double(logged) * 100) : 0 }
}

struct PrayerStats {
    let daysTracked: Int
    let completionRate: Int
    let onTimeRate: Int
    let totalLogged: Int
    let totalOnTime: Int
    let totalMadeUp: Int
    let currentStreak: Int
    let longestStreak: Int
    let byPrayer: [String: PrayerPrayerStat]
}

func computeStats(entries: [PrayerEntry], trackingStart: String) -> PrayerStats {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    let cal = Calendar.current
    let startDate = fmt.date(from: trackingStart) ?? Date()
    let now = Date()
    let daysTracked = max(1, (cal.dateComponents([.day], from: startDate, to: now).day ?? 0) + 1)

    var totalOnTime = 0, totalMadeUp = 0
    var byRaw: [String: (logged: Int, onTime: Int, madeUp: Int)] = [:]
    for entry in entries {
        var b = byRaw[entry.prayerId] ?? (0, 0, 0)
        b.logged += 1
        if entry.madeUp { b.madeUp += 1; totalMadeUp += 1 }
        else             { b.onTime += 1; totalOnTime += 1 }
        byRaw[entry.prayerId] = b
    }

    let totalLogged = entries.count
    let expected = daysTracked * 5
    let completionRate = expected > 0 ? min(100, Int(Double(totalLogged) / Double(expected) * 100)) : 0
    let onTimeRate = totalLogged > 0 ? Int(Double(totalOnTime) / Double(totalLogged) * 100) : 0

    // Streak: consecutive days with all 5 prayers
    var dayCount: [String: Int] = [:]
    for entry in entries { dayCount[entry.dayKey, default: 0] += 1 }
    let fullDays = dayCount.filter { $0.value >= 5 }.keys.sorted()

    var tempStreak = 0, longestStreak = 0
    var prevDate: Date? = nil
    for dayStr in fullDays {
        guard let date = fmt.date(from: dayStr) else { continue }
        if let prev = prevDate,
           (cal.dateComponents([.day], from: prev, to: date).day ?? 0) == 1 {
            tempStreak += 1
        } else {
            tempStreak = 1
        }
        longestStreak = max(longestStreak, tempStreak)
        prevDate = date
    }
    var currentStreak = 0
    if let lastStr = fullDays.last, let lastDate = fmt.date(from: lastStr) {
        if (cal.dateComponents([.day], from: lastDate, to: now).day ?? 0) <= 1 {
            currentStreak = tempStreak
        }
    }

    return PrayerStats(
        daysTracked: daysTracked, completionRate: completionRate,
        onTimeRate: onTimeRate, totalLogged: totalLogged,
        totalOnTime: totalOnTime, totalMadeUp: totalMadeUp,
        currentStreak: currentStreak, longestStreak: longestStreak,
        byPrayer: byRaw.mapValues { v in PrayerPrayerStat(logged: v.logged, onTime: v.onTime, madeUp: v.madeUp) }
    )
}

// MARK: - CSV export

func buildCSV(entries: [PrayerEntry]) -> String {
    var rows = ["Date,Fajr,Dhuhr,Asr,Maghrib,Isha"]
    let byDay = Dictionary(grouping: entries, by: \.dayKey)
    for key in byDay.keys.sorted() {
        let dayEntries = byDay[key]!
        var cells = [key]
        for prayer in Prayer.all {
            if let e = dayEntries.first(where: { $0.prayerId == prayer.id }) {
                cells.append(e.madeUp ? "Made up" : "On time")
            } else {
                cells.append("-")
            }
        }
        rows.append(cells.joined(separator: ","))
    }
    return rows.joined(separator: "\n")
}

// MARK: - Color hex init

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var v: UInt64 = 0
        Scanner(string: h).scanHexInt64(&v)
        let a, r, g, b: UInt64
        switch h.count {
        case 3:  (a,r,g,b) = (255,(v>>8)*17,(v>>4 & 0xF)*17,(v & 0xF)*17)
        case 6:  (a,r,g,b) = (255,v>>16,v>>8 & 0xFF,v & 0xFF)
        case 8:  (a,r,g,b) = (v>>24,v>>16 & 0xFF,v>>8 & 0xFF,v & 0xFF)
        default: (a,r,g,b) = (255,255,255,255)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255,
                  blue: Double(b)/255, opacity: Double(a)/255)
    }
}

// MARK: - Helpers

func makeDayKey(_ date: Date = Date()) -> String {
    let fmt = DateFormatter()
    fmt.dateFormat = "yyyy-MM-dd"
    return fmt.string(from: date)
}

func currentMinutes() -> Int {
    let c = Calendar.current
    return c.component(.hour, from: Date()) * 60 + c.component(.minute, from: Date())
}

func fmtClock(_ mins: Int) -> String {
    let h24 = mins / 60, m = mins % 60
    let ap = h24 >= 12 ? "PM" : "AM"
    let h12 = h24 % 12 == 0 ? 12 : h24 % 12
    return String(format: "%d:%02d %@", h12, m, ap)
}

func fmtLeft(_ secs: Int) -> String {
    if secs <= 0 { return "now" }
    let h = secs / 3600, m = (secs % 3600) / 60
    return h > 0 ? "\(h)h \(m)m" : "\(m)m"
}

func decoratePrayers(prayers: [Prayer], entries: [PrayerEntry], nowMin: Int) -> [PrayerViewModel] {
    var currentId: String? = nil
    for p in prayers where p.timeMinutes <= nowMin { currentId = p.id }

    return prayers.map { prayer in
        if let entry = entries.first(where: { $0.prayerId == prayer.id }) {
            return PrayerViewModel(prayer: prayer, display: .prayed(madeUp: entry.madeUp))
        } else if prayer.timeMinutes > nowMin {
            return PrayerViewModel(prayer: prayer, display: .upcoming)
        } else if prayer.id == currentId {
            return PrayerViewModel(prayer: prayer, display: .now)
        } else {
            return PrayerViewModel(prayer: prayer, display: .missed)
        }
    }
}

func decoratePrayers(entries: [PrayerEntry], nowMin: Int) -> [PrayerViewModel] {
    decoratePrayers(prayers: Prayer.fallback, entries: entries, nowMin: nowMin)
}
