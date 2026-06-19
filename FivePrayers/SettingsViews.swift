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
    @ObservedObject var prayerTimeCache: PrayerTimeCache
    @ObservedObject var citySearchService: CitySearchService

    @Query private var allEntries: [PrayerEntry]

    @State private var showDatePicker = false
    @State private var showCitySearch = false

    @Environment(\.openURL) private var openURL

    private let websiteURL = URL(string: "https://awaismirza.github.io/five-prayers")!
    private let supportURL = URL(string: "https://awaismirza.github.io/five-prayers/#support")!
    private let termsURL = URL(string: "https://awaismirza.github.io/five-prayers/#terms")!
    private let privacyURL = URL(string: "https://awaismirza.github.io/five-prayers/#privacy")!

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

                    // Prayer Times
                    SettingSection(title: "Prayer Times", T: T) {
                        VStack(spacing: 10) {
                            // Selected city row
                            VStack(spacing: 0) {
                                SettingRow(
                                    T: T,
                                    label: "City",
                                    detail: prayerTimeCache.selectedLocation.map { "\($0.city), \($0.country)" } ?? "Not set"
                                ) { showCitySearch = true }

                                if let year = prayerTimeCache.cachedYear {
                                    Divider().background(T.line)
                                    HStack {
                                        Text("Cached year")
                                            .font(.system(size: 13))
                                            .foregroundStyle(T.muted)
                                        Spacer()
                                        Text(String(year))
                                            .font(.system(size: 13))
                                            .foregroundStyle(T.faint)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }

                                if let lastDate = prayerTimeCache.lastDownloadDate {
                                    Divider().background(T.line)
                                    HStack {
                                        Text("Last updated")
                                            .font(.system(size: 13))
                                            .foregroundStyle(T.muted)
                                        Spacer()
                                        Text(fmtDateTime(lastDate))
                                            .font(.system(size: 13))
                                            .foregroundStyle(T.faint)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                }
                            }
                            .background(T.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))

                            // Calculation method picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Calculation method")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(T.text)
                                Picker("Method", selection: $prayerTimeCache.calculationMethod) {
                                    Text("Muslim World League").tag(3)
                                    Text("ISNA").tag(2)
                                    Text("Egyptian GA").tag(5)
                                    Text("Umm al-Qura").tag(4)
                                    Text("Gulf Region").tag(8)
                                    Text("Kuwait").tag(9)
                                    Text("Qatar").tag(10)
                                    Text("Singapore / MUIS").tag(11)
                                    Text("Turkey / Diyanet").tag(13)
                                }
                                .pickerStyle(.menu)
                                .tint(T.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(T.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))

                            // Asr school picker
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Asr calculation school")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(T.text)
                                Picker("School", selection: $prayerTimeCache.school) {
                                    Text("Standard (Shafi'i / Maliki / Hanbali)").tag(0)
                                    Text("Hanafi").tag(1)
                                }
                                .pickerStyle(.menu)
                                .tint(T.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(14)
                            .background(T.card)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))

                            // Refresh button
                            Button(action: refreshTimes) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Refresh prayer times")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundStyle(prayerTimeCache.selectedLocation != nil ? T.text : T.muted)
                                        Text(prayerTimeCache.isDownloading ? "Downloading…" : "Re-download full year of prayer times")
                                            .font(.system(size: 13))
                                            .foregroundStyle(T.muted)
                                    }
                                    Spacer()
                                    if prayerTimeCache.isDownloading {
                                        ProgressView()
                                            .tint(T.primary)
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise.circle")
                                            .font(.system(size: 20))
                                            .foregroundStyle(prayerTimeCache.selectedLocation != nil ? T.primary : T.faint)
                                    }
                                }
                                .padding(14)
                                .background(T.card)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                            }
                            .buttonStyle(ScaleButtonStyle(scale: 0.98))
                            .disabled(prayerTimeCache.selectedLocation == nil || prayerTimeCache.isDownloading)

                            // Disclaimer
                            Text("Prayer times are calculated estimates from your selected city. Please follow your local mosque timetable where required.")
                                .font(.system(size: 12))
                                .foregroundStyle(T.faint)
                                .lineSpacing(3)
                                .padding(.top, 2)
                        }
                    }
                    .onChange(of: prayerTimeCache.calculationMethod) { _, _ in triggerRedownload() }
                    .onChange(of: prayerTimeCache.school)             { _, _ in triggerRedownload() }

                    // Notifications
                    SettingSection(title: "Notifications", T: T) {
                        ToggleRow(T: T, label: "Remind me",
                                  detail: "Notify me when each prayer begins",
                                  value: $remindersEnabled)
                    }
                    .onChange(of: remindersEnabled) { _, enabled in
                        Task {
                            await PrayerNotificationService.shared.refreshSchedule(
                                remindersEnabled: enabled,
                                prayerTimeCache: prayerTimeCache
                            )
                        }
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
                            Text("Five Prayers")
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

                    SettingSection(title: "Links", T: T) {
                        VStack(spacing: 0) {
                            SettingRow(T: T, label: "Website",
                                       detail: "Open the product website") {
                                openURL(websiteURL)
                            }
                            Divider().background(T.line)
                            SettingRow(T: T, label: "Support",
                                       detail: "Open support") {
                                openURL(supportURL)
                            }
                            Divider().background(T.line)
                            SettingRow(T: T, label: "Terms & Conditions",
                                       detail: "Open terms and conditions") {
                                openURL(termsURL)
                            }
                            Divider().background(T.line)
                            SettingRow(T: T, label: "Privacy Policy",
                                       detail: "Open privacy policy") {
                                openURL(privacyURL)
                            }
                        }
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
        .sheet(isPresented: $showCitySearch) {
            CitySearchSheet(
                T: T,
                citySearchService: citySearchService,
                prayerTimeCache: prayerTimeCache,
                locationName: $locationName
            ) { showCitySearch = false }
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

    private func fmtDateTime(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateStyle = .short
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    private func parseDate(_ s: String) -> Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return fmt.date(from: s) ?? Date()
    }

    private func triggerRedownload() {
        guard let loc = prayerTimeCache.selectedLocation else { return }
        Task {
            await prayerTimeCache.clearAndRedownload(
                location: loc,
                method: prayerTimeCache.calculationMethod,
                school: prayerTimeCache.school
            )
            await PrayerNotificationService.shared.refreshSchedule(
                remindersEnabled: remindersEnabled,
                prayerTimeCache: prayerTimeCache
            )
        }
    }

    private func refreshTimes() {
        guard let loc = prayerTimeCache.selectedLocation else { return }
        Task {
            await prayerTimeCache.clearAndRedownload(
                location: loc,
                method: prayerTimeCache.calculationMethod,
                school: prayerTimeCache.school
            )
            await PrayerNotificationService.shared.refreshSchedule(
                remindersEnabled: remindersEnabled,
                prayerTimeCache: prayerTimeCache
            )
        }
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

// MARK: - City Search Sheet

struct CitySearchSheet: View {
    let T: AppTheme
    @ObservedObject var citySearchService: CitySearchService
    @ObservedObject var prayerTimeCache: PrayerTimeCache
    @Binding var locationName: String
    let onDismiss: () -> Void

    @State private var isResolving = false
    @State private var resolveError: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                T.page.ignoresSafeArea()
                VStack(alignment: .leading, spacing: 0) {
                    // Search field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(T.muted)
                        TextField("Search city", text: Binding(
                            get: { citySearchService.query },
                            set: { citySearchService.updateQuery($0) }
                        ))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                        .onAppear { citySearchService.updateQuery("") }
                        if !citySearchService.query.isEmpty {
                            Button { citySearchService.updateQuery("") } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(T.muted)
                            }
                        }
                    }
                    .padding(13)
                    .background(T.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(T.line, lineWidth: 1))
                    .padding(.horizontal, 18)
                    .padding(.top, 16)

                    // Results
                    if !citySearchService.results.isEmpty && !citySearchService.query.isEmpty {
                        ScrollView {
                            VStack(spacing: 0) {
                                let capped = Array(citySearchService.results.prefix(10))
                                ForEach(Array(capped.enumerated()), id: \.element.id) { idx, result in
                                    Button { selectCity(result) } label: {
                                        HStack(spacing: 12) {
                                            Image(systemName: "mappin")
                                                .font(.system(size: 13))
                                                .foregroundStyle(T.muted)
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(result.title)
                                                    .font(.system(size: 14, weight: .semibold))
                                                    .foregroundStyle(T.text)
                                                    .lineLimit(1)
                                                if !result.subtitle.isEmpty {
                                                    Text(result.subtitle)
                                                        .font(.system(size: 12))
                                                        .foregroundStyle(T.muted)
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                    }
                                    .buttonStyle(.plain)
                                    if idx < capped.count - 1 {
                                        Divider().background(T.line).padding(.horizontal, 18)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }

                    // Loading
                    if isResolving || prayerTimeCache.isDownloading {
                        HStack(spacing: 8) {
                            ProgressView().tint(T.primary).scaleEffect(0.8)
                            Text(isResolving ? "Finding city…" : "Downloading prayer times…")
                                .font(.system(size: 13))
                                .foregroundStyle(T.muted)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 12)
                    }

                    // Error
                    if let err = resolveError {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(T.amber)
                            .padding(.horizontal, 18)
                            .padding(.top, 8)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Choose City")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        citySearchService.updateQuery("")
                        onDismiss()
                    }
                }
            }
        }
    }

    private func selectCity(_ result: CitySearchResult) {
        isResolving = true
        resolveError = nil
        citySearchService.updateQuery("")

        Task {
            do {
                let location = try await citySearchService.resolve(result)
                prayerTimeCache.saveSelectedLocation(location)
                locationName = "\(location.city), \(location.country)"
                isResolving = false

                await prayerTimeCache.clearAndRedownload(
                    location: location,
                    method: prayerTimeCache.calculationMethod,
                    school: prayerTimeCache.school
                )
                await PrayerNotificationService.shared.refreshSchedule(
                    remindersEnabled: (UserDefaults.standard.object(forKey: "remindersEnabled") as? Bool) ?? true,
                    prayerTimeCache: prayerTimeCache
                )
                onDismiss()
            } catch {
                isResolving = false
                resolveError = "Couldn't find city. Please try a different search."
            }
        }
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
