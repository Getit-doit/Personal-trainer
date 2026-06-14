# Functional Strength & Longevity Trainer 🏋️

A native iPhone app built around one athlete's profile and goals: **functional
lean strength + longevity**, trained 3 days/week (scaling toward 5), with a
desk job, limited sleep, high stress, and an ankle that inflames easily. Built
with **SwiftUI**, **SwiftData**, and **Swift Charts**.

## The athlete this is tuned for

- 33M, 5'10", started this block at 217 lb, weekday morning training
- Goals: functional lean strength + longevity
- Constraints: 6–7 hrs sleep, high stress, ankle inflames easily (mandatory
  ankle warm-up; introduce incline/impact/sprints/stairs gradually)
- Schedule: 3 days/week, compound-first full-body, scaling toward 5

These are seeded into the user profile on first launch and inform the coach and
the warm-up gate.

## Core features

| # | Feature | Where |
| - | ------- | ----- |
| 1 | **Workout logging** — weight (type a number **or** load a **visual barbell**: tap plates to add per side, tap a loaded plate to remove; 5–45 lb plates in 5 lb steps + optional 2.5/1.25 lb micro plates), sets, reps, **RPE**, and **reps-in-tank** per set; compound-first 3-day full-body templates (A/B/C). | Train |
| 2 | **Progressive overload tracking** — per-lift estimated-1RM history chart; priority lifts (RDL, goblet squat) flag as *ready to progress* with a suggested weight. | Today + Progress |
| 3 | **Personal bests** — auto-detected on finish (Epley est. 1RM) plus manual historical entry. | Progress |
| 4 | **Nutrition (one lever at a time)** — daily wins, weak links, and a single focus "lever" instead of full macro counting. | Fuel |
| 5 | **Recovery inputs** — daily sleep hours + stress level, surfaced with an autoregulation cue. | Today |
| 6 | **Cardio finisher** — low-impact by default (incline walk: duration / speed / incline) with ankle-load tracking. | Train (in a session) |
| 7 | **Warm-up checklist** — required ankle warm-up gate that locks set logging until it's done. | Train (in a session) |
| 8 | **Rest timer** — auto-starts when you complete a set (3 min after compounds, 90 s after accessories) with pause / ±15 s / preset controls and a finish chime. | Train (in a session) |
| 9 | **Apple Music** — pick a workout playlist from your library and start / pause / skip it without leaving the session. | Train (in a session) |
| 10 | **Rest-timer Live Activity** — the rest countdown appears on the Lock Screen and in the Dynamic Island, counting down on its own. | System (widget extension) |
| 11 | **Apple Health** — reads last-night sleep, today's steps, and latest body weight; saves finished workouts as strength training; pull Health sleep into your recovery log. | Today + on finish |
| 12 | **Supersets** — link an exercise with the next so they run back-to-back; the rest timer waits until the last exercise in the group. | Train (in a session) |
| 13 | **Drop sets** — generate a ladder from a start weight, dropping by a set amount at each failure down to an end weight, with no rest between drops. | Train (in a session) |

Plus an **AI Coach** tab — constraint-aware (ankle, sleep, single-lever
nutrition). Works offline; optionally upgrades to the Claude API.

All data is stored locally on-device via SwiftData — no account or network
required.

## Data models

Mapped from the project spec (`PersonalTrainer/Models/Models.swift`):

| Spec model | App type | Notes |
| ---------- | -------- | ----- |
| User | `UserProfile` | name, height, startWeight, goals, constraints[], schedule |
| Exercise | `Exercise` | name, type (compound/accessory), muscleGroup, priority flag, targets, increment |
| WorkoutSession | `WorkoutSession` | date, exercises[], cardio, notes, steamRoom, ankleWarmupDone |
| SetLog | `SetLog` | weight, reps, rpe, repsInTank (+ estimated 1RM) |
| PersonalBest | `PersonalBest` | exercise, value (est. 1RM), date, source (logged/manual) |
| NutritionLog | `NutritionLog` | date, wins[], weakLinks[], currentLever |
| RecoveryLog | `RecoveryLog` | date, sleepHours, stressLevel |
| (cardio) | `CardioEntry` | modality, duration, speed, incline, ankleLoad |

### Progression logic

A lift is flagged **ready to progress** when, in its most recent completed
session, **every working set hit the target reps** *and* kept at least ~2 reps
in tank (RPE ≤ 8). When ready, the app suggests the last top-set weight plus the
lift's increment. See `Services/ProgressionEngine.swift`.

## Requirements

- **Xcode 16+** (uses Xcode's synchronized file groups)
- iOS **17.0+** target
- A Mac to build; an iPhone or the iOS Simulator to run

## Run it

1. Open `PersonalTrainer.xcodeproj` in Xcode.
2. Select the **PersonalTrainer** scheme + a simulator or your device.
3. Press **⌘R**.

To run on your own iPhone, plug it in, pick it as the destination, and set your
Apple ID under **Signing & Capabilities** (bundle id
`com.getitdoit.PersonalTrainer`).

## Enable the live Claude coach (optional)

The Coach works offline out of the box. To use Claude for richer replies:

1. Get a key from the [Anthropic Console](https://console.anthropic.com/).
2. In `PersonalTrainer/Services/CoachService.swift`, set
   `Config.anthropicAPIKey = "sk-ant-..."`.
3. Run — the coach now calls `claude-sonnet-4-6` with the athlete's profile as
   system context.

> Don't commit a real key. For production, proxy through your own backend.

## Project structure

```
PersonalTrainer/
├── PersonalTrainerApp.swift        # App entry + SwiftData container
├── Theme.swift                     # Colors + reusable Card
├── Models/
│   ├── Models.swift                # All @Model types
│   └── ExerciseLibrary.swift       # Catalog, 3-day split, ankle warm-up
├── Services/
│   ├── SeedData.swift              # First-launch profile + catalog
│   ├── SessionFactory.swift        # Build sessions from templates
│   ├── ProgressionEngine.swift     # Progression flags + PR detection
│   ├── RestTimer.swift             # Countdown + drives the Live Activity
│   ├── MusicService.swift          # Apple Music playback (MediaPlayer)
│   ├── HealthService.swift         # HealthKit reads/writes
│   └── CoachService.swift          # Offline coach + optional Claude API
└── Views/
    ├── RootView.swift              # Tab navigation
    ├── TodayView.swift             # Recovery, Health, progression, start
    ├── TrainView.swift             # Session history + start
    ├── ActiveSessionView.swift     # Warm-up gate, RPE logging, music, cardio
    ├── RestTimerBar.swift          # Bottom rest-timer controls
    ├── PlateCalculatorView.swift   # Visual barbell loader (tap plates)
    ├── DropSetSheet.swift          # Drop-set ladder builder
    ├── PlaylistPickerView.swift    # Apple Music playlist picker
    ├── ExercisePickerView.swift
    ├── ProgressDashboardView.swift # PRs + per-lift progression chart
    ├── FuelView.swift              # One-lever nutrition
    └── CoachView.swift

Shared/RestActivityAttributes.swift  # Live Activity data (app + widget)
RestTimerWidget/                     # Widget extension target
├── RestTimerWidgetBundle.swift
└── RestTimerLiveActivity.swift
Config/                              # Info.plists + entitlements
```

## Targets & capabilities

The project has **two targets**:

- **PersonalTrainer** — the app. Uses a manual `Info.plist`
  (`Config/PersonalTrainer-Info.plist`) so it can declare
  `NSSupportsLiveActivities` and the HealthKit usage strings, and a HealthKit
  entitlement (`Config/PersonalTrainer.entitlements`).
- **RestTimerWidget** — a WidgetKit app extension that hosts the rest-timer
  Live Activity. It shares `Shared/RestActivityAttributes.swift` with the app.

On first build you may need to:
1. Select your **Team** for *both* targets under Signing & Capabilities
   (HealthKit + Live Activities require a real team for device builds).
2. Confirm the **HealthKit** capability is present on the app target (it's wired
   via the entitlements file).

> Live Activities and Health reads are best tested on a real device. The
> Simulator supports Live Activities (iOS 16.2+) but has no Health/Music data.

## Apple Music note

The Music controls use the **MediaPlayer** framework and the system music
player, so they work with playlists already in your library (the
`NSAppleMusicUsageDescription` permission is set in the target build settings).
The **iOS Simulator has no music library**, so test playback on a real device
signed into Apple Music.

## Roadmap ideas

- Editable user profile + custom templates
- 1RM trend annotations and deload prompts when recovery dips
- Background body-weight + HRV trends from Health for a longevity dashboard
- Interactive Live Activity buttons (pause/skip from the Lock Screen)
