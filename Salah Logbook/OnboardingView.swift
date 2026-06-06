import SwiftUI

struct OnboardingView: View {
    let T: AppTheme
    @Binding var trackingStart: String
    @Binding var locationName: String
    @Binding var remindersEnabled: Bool
    @ObservedObject var citySearchService: CitySearchService
    @ObservedObject var prayerTimeCache: PrayerTimeCache
    let onComplete: () -> Void

    @State private var step = 0
    @State private var selectedDate = Date()
    @State private var reminders = true
    @State private var isResolvingCity = false
    @State private var citySelectError: String? = nil

    private let totalSteps = 4

    var body: some View {
        ZStack {
            T.page.ignoresSafeArea()
            VStack(spacing: 0) {
                progressBar
                    .padding(.top, 56)
                    .padding(.horizontal, 24)

                TabView(selection: $step) {
                    step0.tag(0)
                    step1.tag(1)
                    step2.tag(2)
                    step3.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: step)

                buttons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
            }
        }
        .onAppear {
            let fmt = DateFormatter()
            fmt.dateFormat = "yyyy-MM-dd"
            selectedDate = fmt.date(from: trackingStart) ?? Date()
            reminders = remindersEnabled
        }
    }

    private var progressBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { i in
                Capsule()
                    .fill(i <= step ? T.primary : T.line)
                    .frame(height: 3)
                    .animation(.easeInOut(duration: 0.3), value: step)
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            if step > 0 {
                Button("Back") { withAnimation { step -= 1 } }
                    .font(.system(size: 15, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(T.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(T.line, lineWidth: 1))
                    .foregroundStyle(T.text)
                    .buttonStyle(ScaleButtonStyle(scale: 0.97))
            }
            Button(step == totalSteps - 1 ? "Get started" : "Next") {
                if step < totalSteps - 1 {
                    withAnimation { step += 1 }
                } else {
                    finish()
                }
            }
            .font(.system(size: 15, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(step == 2 && isNextDisabled ? T.line : T.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(step == 2 && isNextDisabled ? T.muted : T.onPrimary)
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
            .disabled(step == 2 && isNextDisabled)
        }
    }

    private var isNextDisabled: Bool {
        prayerTimeCache.selectedLocation == nil || isResolvingCity
    }

    // MARK: - Step pages

    private var step0: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("🤝")
                .font(.system(size: 64))
                .padding(.bottom, 24)
            Text("Welcome to Your Prayers")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(T.text)
                .kerning(-0.5)
                .multilineTextAlignment(.center)
            Text("A gentle companion for your daily Salah")
                .font(.system(size: 14))
                .foregroundStyle(T.muted)
                .padding(.top, 8)
            Text("Track your five daily prayers, stay consistent, and celebrate your progress.")
                .font(.system(size: 15))
                .foregroundStyle(T.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.top, 20)
                .padding(.horizontal, 8)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var step1: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader("When did you start?", sub: "Your tracking journey begins here")
            DatePicker(
                "Start date",
                selection: $selectedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .tint(T.primary)
            .padding(.top, 20)
            Text("You can change this anytime in Settings.")
                .font(.system(size: 13))
                .foregroundStyle(T.muted)
                .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private var step2: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                stepHeader("Choose your city", sub: "We use your city to download accurate prayer times.")

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
                    if !citySearchService.query.isEmpty {
                        Button {
                            citySearchService.updateQuery("")
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(T.muted)
                        }
                    }
                }
                .padding(13)
                .background(T.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(T.line, lineWidth: 1))
                .padding(.top, 20)

                // Autocomplete results
                if !citySearchService.results.isEmpty && !citySearchService.query.isEmpty {
                    VStack(spacing: 0) {
                        let capped = Array(citySearchService.results.prefix(7))
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
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)
                            if idx < capped.count - 1 {
                                Divider()
                                    .background(T.line)
                                    .padding(.horizontal, 14)
                            }
                        }
                    }
                    .background(T.card)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(T.line, lineWidth: 1))
                    .padding(.top, 8)
                }

                // Selected city card
                if let location = prayerTimeCache.selectedLocation, citySearchService.query.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(T.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.city)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(T.text)
                            Text(location.country)
                                .font(.system(size: 13))
                                .foregroundStyle(T.muted)
                        }
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(T.prayed)
                    }
                    .padding(14)
                    .background(T.card)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(T.line, lineWidth: 1))
                    .padding(.top, 16)
                }

                // Loading state
                if isResolvingCity || prayerTimeCache.isDownloading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .tint(T.primary)
                            .scaleEffect(0.8)
                        Text(isResolvingCity ? "Finding city…" : "Downloading prayer times…")
                            .font(.system(size: 13))
                            .foregroundStyle(T.muted)
                    }
                    .padding(.top, 12)
                }

                // Error
                if let err = citySelectError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(T.amber)
                        .padding(.top, 8)
                }

                Text("You can change this later in Settings.")
                    .font(.system(size: 13))
                    .foregroundStyle(T.muted)
                    .padding(.top, 12)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 24)
        }
    }

    private var step3: some View {
        VStack(alignment: .leading, spacing: 0) {
            stepHeader("Stay reminded", sub: "Optional: get notified before each prayer")
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Enable reminders")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(T.text)
                    Text("15 minutes before each prayer")
                        .font(.system(size: 13))
                        .foregroundStyle(T.muted)
                }
                Spacer()
                Toggle("", isOn: $reminders)
                    .tint(T.primary)
                    .labelsHidden()
            }
            .padding(14)
            .background(T.card)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .strokeBorder(T.line, lineWidth: 1))
            .padding(.top, 20)
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    private func stepHeader(_ title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(T.text)
                .kerning(-0.5)
            Text(sub)
                .font(.system(size: 14))
                .foregroundStyle(T.muted)
        }
        .padding(.top, 40)
    }

    private func selectCity(_ result: CitySearchResult) {
        isResolvingCity = true
        citySelectError = nil
        citySearchService.updateQuery("")

        Task {
            do {
                let location = try await citySearchService.resolve(result)
                prayerTimeCache.saveSelectedLocation(location)
                locationName = "\(location.city), \(location.country)"
                isResolvingCity = false

                await prayerTimeCache.clearAndRedownload(
                    location: location,
                    method: prayerTimeCache.calculationMethod,
                    school: prayerTimeCache.school
                )

                if prayerTimeCache.errorMessage != nil {
                    citySelectError = "Couldn't download prayer times right now. We'll use fallback times and you can refresh in Settings."
                    prayerTimeCache.errorMessage = nil
                }
            } catch {
                isResolvingCity = false
                citySelectError = "Couldn't find city location. Please try a different search."
            }
        }
    }

    private func finish() {
        trackingStart = makeDayKey(selectedDate)
        remindersEnabled = reminders
        onComplete()
    }
}
