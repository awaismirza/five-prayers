import SwiftUI
import SwiftData
import UIKit

struct SettingsTab: View {
    let T: AppTheme
    @Binding var trackingStart: String
    @Binding var locationName: String
    @Binding var remindersEnabled: Bool
    @Binding var accentRaw: String
    @Binding var showArabic: Bool

    @Query private var allEntries: [PrayerEntry]

    @State private var showDatePicker = false
    @State private var showLocationInput = false
    @State private var locationInput = ""

    var body: some View {
        ZStack {
            T.page.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    // Header
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Preferences")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(T.muted)
                        Text("Settings")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(T.text)
                            .kerning(-0.4)
                    }
                    .padding(.bottom, 24)

                    // Appearance
                    SettingSection(title: "Appearance", T: T) {
                        // Accent picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Accent color")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(T.text)
                            HStack(spacing: 16) {
                                ForEach(AccentColor.allCases, id: \.rawValue) { accent in
                                    let selected = accentRaw == accent.rawValue
                                    let aT = AppTheme.make(dark: T.dark, accent: accent)
                                    Button { accentRaw = accent.rawValue } label: {
                                        VStack(spacing: 6) {
                                            ZStack {
                                                Circle().fill(aT.primary)
                                                    .frame(width: 32, height: 32)
                                                if selected {
                                                    Circle()
                                                        .strokeBorder(aT.primary, lineWidth: 2.5)
                                                        .frame(width: 40, height: 40)
                                                }
                                            }
                                            Text(accent.label)
                                                .font(.system(size: 11, weight: .medium))
                                                .foregroundStyle(selected ? T.text : T.muted)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(T.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))

                        // Arabic names
                        ToggleRow(T: T, label: "Arabic names",
                                  detail: "Show Arabic script beside prayer names",
                                  value: $showArabic)
                    }

                    // Tracking
                    SettingSection(title: "Tracking", T: T) {
                        VStack(spacing: 0) {
                            SettingRow(T: T, label: "Started tracking",
                                       detail: fmtDate(trackingStart)) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showDatePicker.toggle()
                                }
                            }
                            if showDatePicker {
                                Divider().background(T.line)
                                DatePicker(
                                    "Start date",
                                    selection: Binding(
                                        get: { parseDate(trackingStart) },
                                        set: { trackingStart = makeDayKey($0) }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .tint(T.primary)
                                .padding(.horizontal, 8)
                                .padding(.bottom, 8)
                            }
                        }
                        .background(T.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                    }

                    // Location
                    SettingSection(title: "Location", T: T) {
                        VStack(spacing: 0) {
                            SettingRow(T: T, label: "Prayer times for",
                                       detail: locationName) {
                                locationInput = locationName
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showLocationInput.toggle()
                                }
                            }
                            if showLocationInput {
                                Divider().background(T.line)
                                VStack(alignment: .leading, spacing: 8) {
                                    TextField("City name", text: $locationInput)
                                        .font(.system(size: 14))
                                        .padding(10)
                                        .background(T.cardSub)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(RoundedRectangle(cornerRadius: 8)
                                            .strokeBorder(T.line, lineWidth: 1))
                                        .onSubmit {
                                            locationName = locationInput
                                            showLocationInput = false
                                        }
                                    Text("GPS-based times will be available in a future update.")
                                        .font(.system(size: 12))
                                        .foregroundStyle(T.faint)
                                }
                                .padding(12)
                            }
                        }
                        .background(T.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                    }

                    // Notifications
                    SettingSection(title: "Notifications", T: T) {
                        ToggleRow(T: T, label: "Remind me",
                                  detail: "15 min before each prayer",
                                  value: $remindersEnabled)
                    }

                    // Data
                    SettingSection(title: "Data", T: T) {
                        Button(action: shareCSV) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Export as CSV")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(T.text)
                                    Text("Download your full prayer log")
                                        .font(.system(size: 13))
                                        .foregroundStyle(T.muted)
                                }
                                Spacer()
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(T.primary)
                            }
                            .padding(14)
                            .background(T.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                        }
                        .buttonStyle(ScaleButtonStyle(scale: 0.98))
                    }

                    // About
                    SettingSection(title: "About", T: T) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your Prayers")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(T.text)
                            Text("A gentle daily reminder to stay connected to your five prayers. Track your journey with consistency, not perfection.")
                                .font(.system(size: 13))
                                .foregroundStyle(T.muted)
                                .lineSpacing(3)
                            Text("Version 1.0 · June 2026")
                                .font(.system(size: 13))
                                .foregroundStyle(T.faint)
                                .padding(.top, 2)
                        }
                        .padding(14)
                        .background(T.card)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                    }

                    Text("All data saved locally to your device.")
                        .font(.system(size: 12.5))
                        .foregroundStyle(T.faint)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
            }
        }
    }

    private func fmtDate(_ dayKey: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        guard let date = fmt.date(from: dayKey) else { return dayKey }
        let disp = DateFormatter()
        disp.dateFormat = "MMM d, yyyy"
        return disp.string(from: date)
    }

    private func parseDate(_ s: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: s) ?? Date()
    }

    private func shareCSV() {
        let csv = buildCSV(entries: allEntries)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("Your_Prayers_\(makeDayKey()).csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        root.present(vc, animated: true)
    }
}

// MARK: - Reusable setting components

struct SettingSection<Content: View>: View {
    let title: String
    let T: AppTheme
    let content: Content

    init(title: String, T: AppTheme, @ViewBuilder content: () -> Content) {
        self.title = title
        self.T = T
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(T.muted)
                .kerning(0.6)
                .padding(.leading, 4)
            content
        }
        .padding(.bottom, 24)
    }
}

struct SettingRow: View {
    let T: AppTheme
    let label: String
    let detail: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(T.text)
                    Text(detail)
                        .font(.system(size: 13))
                        .foregroundStyle(T.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(T.faint)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }
}

struct ToggleRow: View {
    let T: AppTheme
    let label: String
    let detail: String
    @Binding var value: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(T.text)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(T.muted)
            }
            Spacer()
            Toggle("", isOn: $value)
                .tint(T.primary)
                .labelsHidden()
        }
        .padding(14)
        .background(T.card)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
    }
}
