import Foundation

struct MissedPrayerInstance: Identifiable, Hashable {
    let id: String
    let prayerId: String
    let prayerName: String
    let dayKey: String
    let date: Date
    let scheduledTime: Date?
}

