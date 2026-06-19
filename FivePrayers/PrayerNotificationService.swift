import Foundation
import UserNotifications

@MainActor
final class PrayerNotificationService {
    static let shared = PrayerNotificationService()

    private let center = UNUserNotificationCenter.current()
    private let notificationPrefix = "prayer-"
    private let scheduleDays = 10

    private init() {}

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    func requestPermissionIfNeeded() async -> Bool {
        let status = await authorizationStatus()
        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            do {
                return try await center.requestAuthorization(options: [.alert, .sound, .badge])
            } catch {
                return false
            }
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    func refreshSchedule(remindersEnabled: Bool, prayerTimeCache: PrayerTimeCache) async {
        guard remindersEnabled else {
            await cancelPrayerNotifications()
            return
        }

        guard await requestPermissionIfNeeded() else {
            await cancelPrayerNotifications()
            return
        }

        await schedulePrayerNotifications(prayerTimeCache: prayerTimeCache)
    }

    func cancelPrayerNotifications() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(notificationPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func schedulePrayerNotifications(prayerTimeCache: PrayerTimeCache) async {
        await cancelPrayerNotifications()

        let timeZone = prayerTimeCache.selectedLocation
            .flatMap { TimeZone(identifier: $0.timezone) }
            ?? TimeZone.current
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let now = Date()

        for offset in 0..<scheduleDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
            let dayKey = PrayerTimeCache.dateKey(for: date, timezone: timeZone)
            let prayers = Prayer.dailyPrayers(from: prayerTimeCache.prayerTimes(for: date))

            for prayer in prayers {
                guard let fireDate = fireDate(for: dayKey, prayer: prayer, calendar: calendar),
                      fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "\(prayer.name) Prayer"
                content.body = "Time for \(prayer.name). Tap to log your prayer."
                content.sound = .default
                content.userInfo = [
                    "prayerId": prayer.id,
                    "prayerName": prayer.name,
                    "dayKey": dayKey
                ]

                var comps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
                comps.timeZone = timeZone
                let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(notificationPrefix)\(prayer.id)-\(dayKey)",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    private func fireDate(for dayKey: String, prayer: Prayer, calendar: Calendar) -> Date? {
        let parts = dayKey.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        var comps = DateComponents()
        comps.calendar = calendar
        comps.timeZone = calendar.timeZone
        comps.year = parts[0]
        comps.month = parts[1]
        comps.day = parts[2]
        comps.hour = prayer.timeMinutes / 60
        comps.minute = prayer.timeMinutes % 60
        return calendar.date(from: comps)
    }
}
