import SwiftUI

struct MadeUpPrayerSheet: View {
    let prayer: Prayer
    let instances: [MissedPrayerInstance]
    let stat: PrayerPrayerStat
    let T: AppTheme
    let madeUpEntries: [MadeUpPrayerEntry]
    let onMarkMadeUp: (MissedPrayerInstance) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var markedInstanceIds: Set<String> = []

    private var sortedInstances: [MissedPrayerInstance] {
        instances
            .filter { !markedInstanceIds.contains($0.id) }
            .sorted { $0.date < $1.date }
    }

    private var remainingCount: Int {
        sortedInstances.count
    }

    private var madeUpCount: Int {
        stat.madeUp + markedInstanceIds.filter { id in
            instances.contains { $0.id == id }
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                T.page.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("You have \(remainingCount) remaining missed \(prayer.name) prayers.")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(T.text)
                            Text("Made Up: \(madeUpCount)")
                                .font(.system(size: 13))
                                .foregroundStyle(T.muted)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(T.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))

                        if let oldest = sortedInstances.first {
                            Button {
                                mark(oldest)
                            } label: {
                                Text("Mark 1 as Made Up")
                                    .font(.system(size: 15, weight: .bold))
                                    .frame(maxWidth: .infinity)
                                    .padding(14)
                                    .foregroundStyle(T.onPrimary)
                                    .background(T.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                            }
                            .buttonStyle(ScaleButtonStyle(scale: 0.97))
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Missed \(prayer.name) prayers")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundStyle(T.text)

                            if sortedInstances.isEmpty {
                                Text("No remaining missed prayers to make up.")
                                    .font(.system(size: 13))
                                    .foregroundStyle(T.muted)
                                    .padding(14)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(T.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                            } else {
                                VStack(spacing: 10) {
                                    ForEach(sortedInstances) { instance in
                                        missedDateRow(instance)
                                    }
                                }
                            }
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Make Up \(prayer.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .accessibilityLabel("Close")
                }
            }
        }
    }

    private func missedDateRow(_ instance: MissedPrayerInstance) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(formatDay(instance.date))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(T.text)
                Text(instance.prayerName)
                    .font(.system(size: 12.5))
                    .foregroundStyle(T.muted)
            }
            Spacer()
            Button {
                mark(instance)
            } label: {
                Text("Mark Made Up")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(T.onPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(T.primary)
                    .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
        }
        .padding(14)
        .background(T.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
    }

    private func mark(_ instance: MissedPrayerInstance) {
        guard !markedInstanceIds.contains(instance.id) else { return }
        markedInstanceIds.insert(instance.id)
        onMarkMadeUp(instance)
        if sortedInstances.isEmpty {
            dismiss()
        }
    }

    private func formatDay(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, d MMMM"
        return fmt.string(from: date)
    }
}
