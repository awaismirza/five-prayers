import Foundation
import Combine

@MainActor
final class PrayerTimeCache: ObservableObject {
    @Published private(set) var selectedLocation: PrayerLocation?
    @Published private(set) var timesByDate: [String: DailyPrayerTimes] = [:]
    @Published private(set) var isDownloading = false
    @Published private(set) var cachedYear: Int?
    @Published var errorMessage: String?

    @Published var calculationMethod: Int = 3 {
        didSet { UserDefaults.standard.set(calculationMethod, forKey: "prayerCalculationMethod") }
    }
    @Published var school: Int = 0 {
        didSet { UserDefaults.standard.set(school, forKey: "prayerSchool") }
    }
    @Published var lastDownloadDate: Date? {
        didSet { UserDefaults.standard.set(lastDownloadDate, forKey: "lastPrayerTimesDownload") }
    }

    private let apiService = PrayerTimesAPIService()
    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

    // MARK: - Public API

    func load() {
        if let data = UserDefaults.standard.data(forKey: "selectedPrayerLocation"),
           let loc = try? JSONDecoder().decode(PrayerLocation.self, from: data) {
            selectedLocation = loc
        }
        if let stored = UserDefaults.standard.object(forKey: "prayerCalculationMethod") as? Int {
            calculationMethod = stored
        }
        if let stored = UserDefaults.standard.object(forKey: "prayerSchool") as? Int {
            school = stored
        }
        lastDownloadDate = UserDefaults.standard.object(forKey: "lastPrayerTimesDownload") as? Date

        guard let loc = selectedLocation else { return }
        let year = currentYear
        let expectedKey = cacheKey(for: loc, year: year, method: calculationMethod, school: school)
        let storedKey = UserDefaults.standard.string(forKey: "prayerCacheKey")

        if expectedKey == storedKey,
           let data = UserDefaults.standard.data(forKey: "cachedPrayerTimes"),
           let times = try? JSONDecoder().decode([String: DailyPrayerTimes].self, from: data) {
            timesByDate = times
            cachedYear = year
        } else {
            // Stale cache (year, city, method or school changed) — discard it
            clearPersistedTimes()
        }
    }

    /// Called after load() — triggers a re-download if a city is set but cache is empty or stale.
    func checkAndRedownloadIfNeeded() async {
        guard let loc = selectedLocation, timesByDate.isEmpty else { return }
        await clearAndRedownload(location: loc, method: calculationMethod, school: school)
    }

    func saveSelectedLocation(_ location: PrayerLocation) {
        selectedLocation = location
        if let data = try? JSONEncoder().encode(location) {
            UserDefaults.standard.set(data, forKey: "selectedPrayerLocation")
        }
    }

    func prayerTimes(for date: Date) -> DailyPrayerTimes? {
        let tz = selectedLocation.flatMap { TimeZone(identifier: $0.timezone) }
        let key = PrayerTimeCache.dateKey(for: date, timezone: tz)
        return timesByDate[key]
    }

    /// Clears the cache then downloads current month + next month (blocking), then downloads
    /// the remaining months of the current year in a background task.
    ///
    /// Used for onboarding city selection, city changes, method/school changes, and manual refresh.
    /// Callers can await this and proceed once the first two months are ready.
    func clearAndRedownload(location: PrayerLocation, method: Int, school: Int) async {
        clearPersistedTimes()
        timesByDate = [:]
        cachedYear = nil

        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let currentMonth = cal.component(.month, from: now)
        var nextMonth = currentMonth + 1
        var nextYear = year
        if nextMonth > 12 { nextMonth = 1; nextYear += 1 }

        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        await downloadMonthSilent(location: location, month: currentMonth, year: year,
                                  method: method, school: school)
        await downloadMonthSilent(location: location, month: nextMonth, year: nextYear,
                                  method: method, school: school)

        saveCacheKey(for: location, year: year, method: method, school: school)
        lastDownloadDate = Date()
        cachedYear = year

        // Background: download the remaining months of the current year without blocking the caller
        let excludeThisYear: Set<Int> = nextYear == year ? [currentMonth, nextMonth] : [currentMonth]
        Task {
            for month in 1...12 where !excludeThisYear.contains(month) {
                await self.downloadMonthSilent(location: location, month: month, year: year,
                                              method: method, school: school)
            }
            self.saveCacheKey(for: location, year: year, method: method, school: school)
            self.lastDownloadDate = Date()
        }
    }

    func clearCache() {
        timesByDate = [:]
        cachedYear = nil
        clearPersistedTimes()
    }

    static func dateKey(for date: Date, timezone: TimeZone? = nil) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = timezone ?? TimeZone.current
        return fmt.string(from: date)
    }

    // MARK: - Private

    private func cacheKey(for location: PrayerLocation, year: Int, method: Int, school: Int) -> String {
        "\(location.id)|\(year)|\(method)|\(school)"
    }

    private func saveCacheKey(for location: PrayerLocation, year: Int, method: Int, school: Int) {
        let key = cacheKey(for: location, year: year, method: method, school: school)
        UserDefaults.standard.set(key, forKey: "prayerCacheKey")
    }

    private func downloadMonthSilent(location: PrayerLocation, month: Int, year: Int,
                                     method: Int, school: Int) async {
        do {
            let times = try await apiService.fetchMonth(
                location: location, month: month, year: year,
                calculationMethod: method, school: school
            )
            for t in times { timesByDate[t.dateKey] = t }
            persistCache()
        } catch {
            if errorMessage == nil { errorMessage = error.localizedDescription }
        }
    }

    private func persistCache() {
        if let data = try? JSONEncoder().encode(timesByDate) {
            UserDefaults.standard.set(data, forKey: "cachedPrayerTimes")
        }
    }

    private func clearPersistedTimes() {
        UserDefaults.standard.removeObject(forKey: "cachedPrayerTimes")
        UserDefaults.standard.removeObject(forKey: "prayerCacheKey")
    }
}
