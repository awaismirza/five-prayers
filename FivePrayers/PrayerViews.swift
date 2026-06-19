import SwiftUI
import Combine

// MARK: - Checkmark path

struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to:    CGPoint(x: 4/18 * w,   y: 9.5/18  * h))
        p.addLine(to: CGPoint(x: 7.2/18 * w, y: 12.7/18 * h))
        p.addLine(to: CGPoint(x: 14/18 * w,  y: 5.8/18  * h))
        return p
    }
}

// MARK: - Check circle

struct CheckCircleView: View {
    let state: PrayerDisplayState
    let T: AppTheme
    let blooming: Bool
    let size: CGFloat

    @State private var checkProgress: CGFloat
    @State private var popScale: CGFloat = 1
    @State private var bloomScale: CGFloat = 0.45
    @State private var bloomOpacity: Double = 0

    init(state: PrayerDisplayState, T: AppTheme, blooming: Bool, size: CGFloat = 30) {
        self.state = state; self.T = T; self.blooming = blooming; self.size = size
        let initial: CGFloat = { if case .prayed = state { return 1 } else { return 0 } }()
        _checkProgress = State(initialValue: initial)
    }

    private var isPrayed: Bool {
        if case .prayed = state { return true }
        return false
    }

    private var ringColor: Color {
        switch state {
        case .prayed:   return T.prayed
        case .now:      return T.primary
        case .missed:   return T.amber
        case .upcoming: return T.idleRing
        }
    }

    var body: some View {
        ZStack {
            if bloomOpacity > 0 {
                Circle()
                    .fill(T.prayed)
                    .scaleEffect(bloomScale)
                    .opacity(bloomOpacity)
            }
            ZStack {
                Circle().fill(isPrayed ? T.prayed : Color.clear)
                Circle().strokeBorder(ringColor, lineWidth: 2)
                if case .now = state {
                    Circle().fill(T.primary).frame(width: 7, height: 7)
                }
                CheckmarkShape()
                    .trim(from: 0, to: checkProgress)
                    .stroke(
                        isPrayed ? T.onPrimary : Color.clear,
                        style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
                    )
                    .frame(width: size * 0.56, height: size * 0.56)
            }
            .scaleEffect(popScale)
        }
        .frame(width: size, height: size)
        .onChange(of: isPrayed) { _, newValue in
            if newValue {
                withAnimation(.easeOut(duration: 0.4).delay(0.08)) { checkProgress = 1 }
                withAnimation(.interpolatingSpring(stiffness: 420, damping: 13)) { popScale = 1.22 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    withAnimation(.interpolatingSpring(stiffness: 280, damping: 16)) { popScale = 1 }
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) { checkProgress = 0; popScale = 1 }
            }
        }
        .onChange(of: blooming) { _, newValue in
            guard newValue else { return }
            bloomScale = 0.45; bloomOpacity = 0.55
            withAnimation(.easeOut(duration: 0.7)) { bloomScale = 2.8; bloomOpacity = 0 }
        }
    }
}

// MARK: - Prayer icon

struct PrayerIconView: View {
    let id: String
    let color: Color
    let size: CGFloat

    private var symbol: String {
        switch id {
        case "fajr":    return "sun.horizon"
        case "dhuhr":   return "sun.max"
        case "asr":     return "sun.min"
        case "maghrib": return "sunset"
        default:        return "moon.stars"
        }
    }

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: size, weight: .regular))
            .foregroundStyle(color)
    }
}

// MARK: - Progress track

struct ProgressTrackView: View {
    let rows: [PrayerViewModel]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(rows) { row in
                ZStack {
                    Capsule().fill(segColor(for: row))
                    if case .now = row.display {
                        Capsule().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5)
                    }
                }
                .frame(height: 5)
                .animation(.easeInOut(duration: 0.3), value: row.isPrayed)
            }
        }
    }

    private func segColor(for row: PrayerViewModel) -> Color {
        switch row.display {
        case .prayed:   return .white
        case .missed:   return .white.opacity(0.32)
        case .now, .upcoming: return .white.opacity(0.22)
        }
    }
}

// MARK: - Countdown

struct CountdownView: View {
    let targetMin: Int
    let now: Date
    let timeZone: TimeZone?
    @State private var remainingSecs: Int = 0

    var body: some View {
        Text(fmtLeft(remainingSecs))
            .monospacedDigit()
            .onAppear { updateSecs() }
            .onChange(of: now) { _, _ in updateSecs() }
            .onChange(of: targetMin) { _, _ in updateSecs() }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                updateSecs()
            }
    }

    private func updateSecs() {
        var c = Calendar.current
        if let timeZone { c.timeZone = timeZone }
        let current = Date()
        let nowSec = c.component(.hour, from: current) * 3600
                   + c.component(.minute, from: current) * 60
                   + c.component(.second, from: current)
        remainingSecs = max(0, targetMin * 60 - nowSec)
    }
}

// MARK: - Hero

struct HeroView: View {
    let rows: [PrayerViewModel]
    let T: AppTheme
    let now: Date
    let timeZone: TimeZone?
    let blooming: String?
    let onMark: (String) -> Void

    private var prayedCount: Int { rows.filter(\.isPrayed).count }
    private var allDone: Bool { prayedCount == rows.count }

    private var nowRow: PrayerViewModel? {
        rows.first { if case .now = $0.display { return true }; return false }
    }
    private var nextRow: PrayerViewModel? {
        rows.first { if case .upcoming = $0.display { return true }; return false }
    }

    private var kicker: String {
        if allDone        { return "Alhamdulillah" }
        if nowRow != nil  { return "It's time for" }
        if nextRow != nil { return "Next prayer" }
        return "Today"
    }

    private var bigText: String {
        if allDone { return "Today's five, complete" }
        if let r = nowRow  { return "\(r.prayer.name) · \(fmtClock(r.prayer.timeMinutes))" }
        if let r = nextRow { return "\(r.prayer.name) · \(fmtClock(r.prayer.timeMinutes))" }
        return "\(prayedCount) of \(rows.count) prayed"
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 180, height: 180)
                .blur(radius: 8)
                .offset(x: 20, y: -50)
                .allowsHitTesting(false)

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(kicker.uppercased())
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .kerning(0.4)
                    Spacer()
                    Text("\(prayedCount)/\(rows.count) today")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .monospacedDigit()
                }

                Text(bigText)
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(Color.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 10)

                subView
                    .font(.system(size: 14.5))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(2)
                    .padding(.top, 7)

                ProgressTrackView(rows: rows)
                    .padding(.top, 16)

                if let btn = nowRow {
                    ctaButton(btn)
                        .padding(.top, 16)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(
                colors: [T.heroFrom, T.heroTo],
                startPoint: UnitPoint(x: 0.15, y: 0),
                endPoint:   UnitPoint(x: 0.85, y: 1)
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: T.dark ? .black.opacity(0.36) : .black.opacity(0.12), radius: 24, x: 0, y: 16)
    }

    @ViewBuilder
    private var subView: some View {
        if allDone {
            Text("May they be accepted. Rest easy tonight.")
        } else if let current = nowRow, let next = nextRow {
            let _ = current  // suppress unused warning
            HStack(spacing: 0) {
                Text("\(next.prayer.name) follows in ")
                CountdownView(targetMin: next.prayer.timeMinutes, now: now, timeZone: timeZone)
            }
        } else if nowRow != nil {
            Text("The last prayer of the day")
        } else if let next = nextRow {
            HStack(spacing: 0) {
                Text("Begins in ")
                CountdownView(targetMin: next.prayer.timeMinutes, now: now, timeZone: timeZone)
                Text(" — a moment to breathe")
            }
        } else {
            Text("Keep going, gently.")
        }
    }

    @ViewBuilder
    private func ctaButton(_ btn: PrayerViewModel) -> some View {
        Button { onMark(btn.id) } label: {
            HStack(spacing: 9) {
                ZStack {
                    Circle()
                        .strokeBorder(T.primary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    CheckmarkShape()
                        .stroke(T.primary,
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 11, height: 11)
                }
                Text("Mark \(btn.prayer.name) as prayed")
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
            }
            .foregroundStyle(T.primaryDeep)
            .frame(maxWidth: .infinity)
            .padding(13)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.1), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
    }
}

// MARK: - Header

struct HeaderView: View {
    let T: AppTheme
    let hijri: String
    let greg: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text("Assalamu alaikum")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(T.muted)
                Text(hijri)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(T.text)
                    .kerning(-0.4)
                Text(greg)
                    .font(.system(size: 13))
                    .foregroundStyle(T.faint)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(T.card)
                    .overlay(Circle().strokeBorder(T.line, lineWidth: 1))
                    .shadow(
                        color: T.dark ? .black.opacity(0.32) : .black.opacity(0.08),
                        radius: 10, x: 0, y: 6
                    )
                Image(systemName: "person")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(T.muted)
            }
            .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Prayer row

private struct RowTag {
    let label: String
    let color: Color
    let background: Color
}

struct PrayerRowView: View {
    let row: PrayerViewModel
    let T: AppTheme
    let blooming: Bool
    let showArabic: Bool
    let delay: Double
    let animate: Bool
    let onToggle: () -> Void

    @State private var appeared = false

    private var rowBg: Color {
        switch row.display {
        case .prayed: return T.prayedSoft
        case .missed: return T.amberSoft
        default:      return T.card
        }
    }

    private var iconBg: Color {
        switch row.display {
        case .prayed: return T.prayedSoft
        case .missed: return T.amberSoft
        default:      return T.cardSub
        }
    }

    private var iconColor: Color {
        switch row.display {
        case .prayed:   return T.prayedOn
        case .missed:   return T.amberOn
        case .now:      return T.primary
        case .upcoming: return T.faint
        }
    }

    private var nameColor: Color {
        if case .upcoming = row.display { return T.muted }
        return T.text
    }

    private var isNow: Bool {
        if case .now = row.display { return true }
        return false
    }

    private var tag: RowTag? {
        switch row.display {
        case .prayed(let madeUp):
            return RowTag(label: madeUp ? "Made up" : "On time",
                          color: T.prayedOn, background: T.prayedSoft)
        case .missed:
            return RowTag(label: "Make up", color: T.amberOn, background: T.amberSoft)
        case .now:
            return RowTag(label: "Now", color: T.onPrimary, background: T.primary)
        case .upcoming:
            return nil
        }
    }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 13).fill(iconBg)
                    RoundedRectangle(cornerRadius: 13).strokeBorder(T.line, lineWidth: 1)
                    PrayerIconView(id: row.prayer.id, color: iconColor, size: 18)
                }
                .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.prayer.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(nameColor)
                            .kerning(-0.2)
                        if showArabic {
                            Text(row.prayer.arabic)
                                .font(.system(size: 14))
                                .foregroundStyle(T.faint)
                        }
                    }
                    Text(fmtClock(row.prayer.timeMinutes))
                        .font(.system(size: 13.5))
                        .monospacedDigit()
                        .foregroundStyle(T.muted)
                }

                Spacer(minLength: 8)

                if let t = tag {
                    Text(t.label)
                        .font(.system(size: 12, weight: .semibold))
                        .kerning(0.1)
                        .foregroundStyle(t.color)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(t.background)
                        .clipShape(Capsule())
                        .fixedSize()
                }

                CheckCircleView(state: row.display, T: T, blooming: blooming, size: 30)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(rowBg)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                Group {
                    if isNow {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(T.primary, lineWidth: 1.5)
                    }
                }
            )
            .shadow(
                color: T.dark ? .black.opacity(0.26) : .black.opacity(0.08),
                radius: 16, x: 0, y: 10
            )
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.985))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            if animate {
                withAnimation(.easeOut(duration: 0.5).delay(delay)) { appeared = true }
            } else {
                appeared = true
            }
        }
    }
}

// MARK: - Shared button style

struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
