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
| 1 | **Workout logging** — weight, sets, reps, **RPE**, and **reps-in-tank** per set; compound-first 3-day full-body templates (A/B/C). | Train |
| 2 | **Progressive overload tracking** — per-lift estimated-1RM history chart; priority lifts (RDL, goblet squat) flag as *ready to progress* with a suggested weight. | Today + Progress |
| 3 | **Personal bests** — auto-detected on finish (Epley est. 1RM) plus manual historical entry. | Progress |
| 4 | **Nutrition (one lever at a time)** — daily wins, weak links, and a single focus "lever" instead of full macro counting. | Fuel |
| 5 | **Recovery inputs** — daily sleep hours + stress level, surfaced with an autoregulation cue. | Today |
| 6 | **Cardio finisher** — low-impact by default (incline walk: duration / speed / incline) with ankle-load tracking. | Train (in a session) |
| 7 | **Warm-up checklist** — required ankle warm-up gate that locks set logging until it's done. | Train (in a session) |

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
│   └── CoachService.swift          # Offline coach + optional Claude API
└── Views/
    ├── RootView.swift              # Tab navigation
    ├── TodayView.swift             # Recovery, progression flags, start
    ├── TrainView.swift             # Session history + start
    ├── ActiveSessionView.swift     # Warm-up gate, RPE logging, cardio
    ├── ExercisePickerView.swift
    ├── ProgressDashboardView.swift # PRs + per-lift progression chart
    ├── FuelView.swift              # One-lever nutrition
    └── CoachView.swift
```

## Roadmap ideas

- **HealthKit** sync for sleep, body weight, and steps (fits the longevity goal)
- Rest timer between sets
- Editable user profile + custom templates
- 1RM trend annotations and deload prompts when recovery dips
