import Foundation
import SwiftData

@Model
final class MadeUpPrayerEntry {
    var id: UUID
    var prayerId: String
    var prayerName: String
    var originalDayKey: String
    var originalDate: Date
    var madeUpAt: Date
    var note: String?

    init(
        prayerId: String,
        prayerName: String,
        originalDayKey: String,
        originalDate: Date,
        madeUpAt: Date = Date(),
        note: String? = nil
    ) {
        self.id = UUID()
        self.prayerId = prayerId
        self.prayerName = prayerName
        self.originalDayKey = originalDayKey
        self.originalDate = originalDate
        self.madeUpAt = madeUpAt
        self.note = note
    }
}

