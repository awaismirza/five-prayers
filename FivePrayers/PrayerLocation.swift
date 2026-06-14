import Foundation

struct PrayerLocation: Codable, Equatable, Identifiable {
    var id: String { "\(city)-\(country)-\(latitude)-\(longitude)" }
    let city: String
    let country: String
    let latitude: Double
    let longitude: Double
    let timezone: String
}

struct CitySearchResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let city: String
    let country: String
    let latitude: Double?
    let longitude: Double?
    let timezone: String?

    static func == (lhs: CitySearchResult, rhs: CitySearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

struct DailyPrayerTimes: Codable, Equatable, Identifiable {
    var id: String { "\(dateKey)-\(locationId)" }
    let dateKey: String
    let locationId: String
    // minutes from midnight
    let fajr: Int
    let dhuhr: Int
    let asr: Int
    let maghrib: Int
    let isha: Int
}
