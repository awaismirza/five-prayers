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

    static let all: [Prayer] = [
        Prayer(id: "fajr",    name: "Fajr",    arabic: "الفجر",  timeMinutes: 5  * 60 + 12),
        Prayer(id: "dhuhr",   name: "Dhuhr",   arabic: "الظهر",  timeMinutes: 13 * 60 + 4),
        Prayer(id: "asr",     name: "Asr",     arabic: "العصر",  timeMinutes: 16 * 60 + 42),
        Prayer(id: "maghrib", name: "Maghrib", arabic: "المغرب", timeMinutes: 19 * 60 + 58),
        Prayer(id: "isha",    name: "Isha",    arabic: "العشاء",  timeMinutes: 21 * 60 + 21),
    ]
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

    static func make(dark: Bool) -> AppTheme {
        dark ? .darkTheme : .lightTheme
    }

    static let lightTheme = AppTheme(
        dark: false,
        page:       Color(hex: "F5F3ED"),
        card:       .white,
        cardSub:    Color(hex: "FBFAF6"),
        line:       Color(hex: "141C1A").opacity(0.07),
        primary:    Color(hex: "14705E"),
        primaryDeep: Color(hex: "0C4A3E"),
        onPrimary:  .white,
        heroFrom:   Color(hex: "14705E"),
        heroTo:     Color(hex: "0C4A3E"),
        prayed:     Color(hex: "3E9E6F"),
        prayedSoft: Color(hex: "E7F2EA"),
        prayedOn:   Color(hex: "2C7E54"),
        amber:      Color(hex: "C98A2E"),
        amberSoft:  Color(hex: "F8EFDC"),
        amberOn:    Color(hex: "9A6916"),
        text:       Color(hex: "23282A"),
        muted:      Color(hex: "7C8682"),
        faint:      Color(hex: "A8B0AC"),
        idleRing:   Color(hex: "D7DCD7")
    )

    static let darkTheme = AppTheme(
        dark: true,
        page:       Color(hex: "0E1513"),
        card:       Color(hex: "18211E"),
        cardSub:    Color(hex: "141C1A"),
        line:       Color.white.opacity(0.07),
        primary:    Color(hex: "4ECBA5"),
        primaryDeep: Color(hex: "0F2C26"),
        onPrimary:  Color(hex: "06140F"),
        heroFrom:   Color(hex: "0F2C26"),
        heroTo:     Color(hex: "0A1714"),
        prayed:     Color(hex: "5FC98C"),
        prayedSoft: Color(hex: "5FC98C").opacity(0.13),
        prayedOn:   Color(hex: "7AD3A0"),
        amber:      Color(hex: "E0A64A"),
        amberSoft:  Color(hex: "E0A64A").opacity(0.14),
        amberOn:    Color(hex: "E9B968"),
        text:       Color(hex: "ECEFEC"),
        muted:      Color(hex: "8FA09A"),
        faint:      Color(hex: "5E6E68"),
        idleRing:   Color(hex: "34403B")
    )
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

func decoratePrayers(entries: [PrayerEntry], nowMin: Int) -> [PrayerViewModel] {
    var currentId: String? = nil
    for p in Prayer.all where p.timeMinutes <= nowMin { currentId = p.id }

    return Prayer.all.map { prayer in
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
