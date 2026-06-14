# Personal Trainer 🏋️

A native iPhone app that acts as your personal trainer — log workouts, follow
guided plans, track progress with charts, and chat with an AI coach. Built with
**SwiftUI**, **SwiftData**, and **Swift Charts**.

## Features

| Tab | What it does |
| --- | --- |
| **Home** | Greeting + weekly stats (workouts, volume lifted, latest body weight) and recent activity. |
| **Workouts** | Create a session, add exercises from a searchable library, log sets/reps/weight, and finish the workout. |
| **Plans** | Five built-in routines (Full Body, Push, Pull, Legs, HIIT). Tap **Start** to spin up a ready-to-log session. |
| **Progress** | Body-weight line chart, weekly training-volume bars, and sets-by-muscle breakdown. Log new weigh-ins. |
| **Coach** | Chat-based AI coach. Works offline out of the box; optionally powered by the Claude API. |

All data is stored locally on-device with SwiftData — no account or network
required.

## Requirements

- **Xcode 16** or later (the project uses Xcode's synchronized file groups)
- iOS **17.0+** target
- A Mac to build and run; a real iPhone or the iOS Simulator to use it

## Run it

1. Open `PersonalTrainer.xcodeproj` in Xcode.
2. Select the **PersonalTrainer** scheme and an iPhone simulator (or your device).
3. Press **⌘R**.

To run on your own iPhone, plug it in, pick it as the run destination, and set
your Apple ID under **Signing & Capabilities** (the bundle id is
`com.getitdoit.PersonalTrainer` — change it if needed).

## Enable the live Claude coach (optional)

The Coach tab ships with a built-in offline trainer so it works with zero setup.
To upgrade it to a real conversational coach powered by Claude:

1. Get an API key from the [Anthropic Console](https://console.anthropic.com/).
2. Open `PersonalTrainer/Services/CoachService.swift` and set:
   ```swift
   enum Config {
       static let anthropicAPIKey = "sk-ant-..."
   }
   ```
3. Run the app — the Coach now calls `claude-sonnet-4-6` for replies.

> **Security note:** Don't commit a real key. For production, proxy requests
> through your own backend instead of shipping the key in the app. `Secrets.swift`
> is already in `.gitignore` if you prefer to move the key there.

## Project structure

```
PersonalTrainer/
├── PersonalTrainerApp.swift     # App entry + SwiftData container
├── Theme.swift                  # Colors and the reusable Card view
├── Models/
│   ├── Models.swift             # WorkoutSession, LoggedExercise, SetEntry, BodyMetric
│   └── ExerciseLibrary.swift    # Exercise catalog + built-in plans
├── Services/
│   ├── SeedData.swift           # First-launch sample data
│   └── CoachService.swift       # Offline coach + optional Claude API
└── Views/
    ├── RootView.swift           # Tab navigation
    ├── DashboardView.swift
    ├── WorkoutsView.swift
    ├── ActiveWorkoutView.swift
    ├── ExercisePickerView.swift
    ├── PlansView.swift
    ├── ProgressDashboardView.swift
    └── CoachView.swift
```

## Roadmap ideas

- Rest timer between sets
- Apple Health / HealthKit sync
- Custom user-defined plans
- Per-exercise PR history and 1RM estimates
- Push notifications / workout reminders
