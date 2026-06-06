import SwiftUI

struct OnboardingView: View {
    let T: AppTheme
    @Binding var trackingStart: String
    @Binding var locationName: String
    @Binding var remindersEnabled: Bool
    let onComplete: () -> Void

    @State private var step = 0
    @State private var selectedDate = Date()
    @State private var locationInput = "Your City"
    @State private var reminders = true

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
            locationInput = locationName
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
            .background(T.primary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .foregroundStyle(T.onPrimary)
            .buttonStyle(ScaleButtonStyle(scale: 0.97))
        }
    }

    // MARK: Step pages

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
        VStack(alignment: .leading, spacing: 0) {
            stepHeader("Where are you?", sub: "To show accurate prayer times")
            TextField("City name", text: $locationInput)
                .font(.system(size: 15))
                .padding(13)
                .background(T.card)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(T.line, lineWidth: 1))
                .padding(.top, 20)
            Text("GPS-based prayer times will be available in a future update.")
                .font(.system(size: 13))
                .foregroundStyle(T.muted)
                .padding(.top, 12)
            Spacer()
        }
        .padding(.horizontal, 24)
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

    private func finish() {
        trackingStart = makeDayKey(selectedDate)
        locationName = locationInput.isEmpty ? "Your City" : locationInput
        remindersEnabled = reminders
        onComplete()
    }
}
