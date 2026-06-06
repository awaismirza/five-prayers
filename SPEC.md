# Salah Logbook — Project Spec

## Overview

A native iOS app (SwiftUI + SwiftData) for tracking the five daily Islamic prayers (Salah). The app is warm, encouraging, and built around the today-screen paradigm — one glance shows where you are in the day, one tap logs a prayer.

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Persistence | SwiftData |
| Settings | UserDefaults via `@AppStorage` |
| Target | iOS 17+ |
| Language | Swift 5.9+ |
| Build system | Xcode 16 (`PBXFileSystemSynchronizedRootGroup`) |

---

## File Structure

```
Salah Logbook/
├── Salah_LogbookApp.swift   — App entry, SwiftData schema
├── Item.swift               — PrayerEntry model, Prayer data, AppTheme, AccentColor,
│                              PrayerStats, helpers (fmtClock, decoratePrayers, buildCSV…)
├── ContentView.swift        — Root shell: onboarding gate + TabView
├── HomeTab.swift            — Today tab: prayer list, hero card, toggle logic
├── PrayerViews.swift        — Reusable prayer UI (CheckCircleView, HeroView, PrayerRowView…)
├── AnalyticsViews.swift     — Analytics tab: streaks, completion rate, breakdown
├── SettingsViews.swift      — Settings tab: accent, tracking date, location, reminders, CSV
└── OnboardingView.swift     — 4-step first-launch wizard
```

---

## Data Model

### `PrayerEntry` (SwiftData `@Model`)

| Field | Type | Description |
|---|---|---|
| `dayKey` | `String` | `yyyy-MM-dd` — scopes entries to a calendar day |
| `prayerId` | `String` | `fajr` \| `dhuhr` \| `asr` \| `maghrib` \| `isha` |
| `madeUp` | `Bool` | `true` if logged after the window passed (made up / qada) |

### Prayers (static)

| ID | Name | Arabic | Default time |
|---|---|---|---|
| fajr | Fajr | الفجر | 5:12 AM |
| dhuhr | Dhuhr | الظهر | 1:04 PM |
| asr | Asr | العصر | 4:42 PM |
| maghrib | Maghrib | المغرب | 7:58 PM |
| isha | Isha | العشاء | 9:21 PM |

> Times are static defaults. GPS-based calculation is planned for a future update.

---

## Prayer Display States

```
.upcoming  — prayer window hasn't opened yet (muted row)
.now       — the current / most recent unprayed prayer (emerald border, "Now" tag)
.missed    — window passed, not prayed (amber tint, "Make up" tag)
.prayed(madeUp: Bool) — logged (green tint, "On time" / "Made up" tag)
```

State is computed live from the current clock minute against the static prayer schedule.

---

## Screens

### 1. Onboarding (first launch only)

Four steps presented in a `TabView` with a paged swipe:

1. **Welcome** — app introduction
2. **Tracking start date** — `DatePicker(.compact)` defaulting to today; saved to `@AppStorage("trackingStart")`
3. **Location** — city name text field; saved to `@AppStorage("locationName")`
4. **Reminders** — toggle for 15-min-before notifications; saved to `@AppStorage("remindersEnabled")`

Completion sets `@AppStorage("onboardingDone") = true`. Never shown again unless UserDefaults is cleared.

---

### 2. Home Tab (`HomeTab`)

**Header** — "Assalamu alaikum" greeting, Hijri date (Islamic Civil calendar), Gregorian date, avatar circle.

**Hero card** — gradient spotlight that adapts to the moment:
- Current prayer: name + time + "Mark X as prayed" CTA button
- Between prayers: countdown to next prayer
- All done: "Today's five, complete" + encouraging message

**5-segment progress track** — one capsule per prayer; white = prayed, dim = upcoming/missed, ring = now.

**Prayer rows** — one card per prayer:
- Icon (SF Symbol per prayer), English name, Arabic name (toggleable), time
- Status tag (pill): Now / On time / Make up / Made up
- CheckCircle: idle ring → pop spring → check draw-in animation + bloom ripple on mark

**Interactions:**
- Tap to toggle prayed/unprayed
- Haptic feedback (`UIImpactFeedbackGenerator(.light)`) on mark
- Bloom ripple (scale 0.45 → 2.8, opacity 0.55 → 0) on mark
- Staggered entrance animation (fade + slide) on first load

---

### 3. Analytics Tab (`AnalyticsTab`)

Stats computed from all `PrayerEntry` records since `trackingStart`.

**Big-number cards (2-column grid):**
- 🔥 Current Streak (consecutive days with all 5 prayed)
- ⭐ Longest Streak
- ✓ Completion Rate (%) = total logged / (daysTracked × 5)
- 🕐 On-Time Rate (%) = on-time / total logged

**Consistency by prayer** — one card per prayer with:
- Logged count + made-up count
- Horizontal bar: green ≥80%, amber ≥50%, red-ish <50%
- On-time percentage label

**Breakdown** — two cards: "On-time" (green number) / "Made up" (amber number)

---

### 4. Settings Tab (`SettingsTab`)

**Appearance**
- Accent color picker: Emerald / Teal / Pine (live preview circles)
- Arabic names toggle

**Tracking**
- Started tracking date (taps to reveal inline `DatePicker(.graphical)`)

**Location**
- City name text field (inline expand)

**Notifications**
- Reminders toggle (15 min before each prayer)

**Data**
- Export as CSV — generates `Date,Fajr,Dhuhr,Asr,Maghrib,Isha` rows, shares via `UIActivityViewController`

**About**
- App name, description, version

---

## Theme System

`AppTheme` is a value type (struct) holding ~20 semantic color tokens. Instantiated via:

```swift
AppTheme.make(dark: Bool, accent: AccentColor = .emerald)
```

### Accent variants

| Accent | Light primary | Dark primary |
|---|---|---|
| Emerald | `#14705E` | `#4ECBA5` |
| Teal | `#0E7490` | `#41C2DE` |
| Pine | `#2C6E55` | `#5BC79E` |

Accent is persisted in `@AppStorage("accent")`. Dark mode follows system `colorScheme`.

---

## Settings Persistence

All user preferences stored in `UserDefaults` via `@AppStorage` in `ContentView`:

| Key | Type | Default |
|---|---|---|
| `onboardingDone` | `Bool` | `false` |
| `accent` | `String` | `"emerald"` |
| `showArabic` | `Bool` | `true` |
| `trackingStart` | `String` | today's `yyyy-MM-dd` |
| `locationName` | `String` | `"Your City"` |
| `remindersEnabled` | `Bool` | `true` |

---

## Animations

| Animation | Trigger | Spec |
|---|---|---|
| Check draw-in | Mark prayer | `.trim(from:0, to:)` 0→1, `.easeOut(0.4)`, 80ms delay |
| Pop spring | Mark prayer | Scale 1 → 1.22 → 1, `interpolatingSpring(stiffness:420, damping:13)` |
| Bloom ripple | Mark prayer | Scale 0.45 → 2.8, opacity 0.55 → 0, `.easeOut(0.7)` |
| Row entrance | First load | Fade+slide, `.easeOut(0.5)`, staggered `i × 55ms` |
| Press scale | Button tap | Scale 0.985, `.easeOut(0.12)` |

---

## Planned / Future Work

- [ ] GPS-based prayer time calculation (AdhanSwift or similar)
- [ ] Local notifications for prayer reminders
- [ ] Weekly / monthly history calendar view
- [ ] iCloud sync
- [ ] Widget (today summary)
- [ ] Apple Watch companion
