# Copilot instructions for this repository

This file gives focused, actionable guidance for an AI coding agent working on the social-battery iOS app.

- Big picture
  - Single-target SwiftUI iOS app. Entry point: `social-battery/social_batteryApp.swift`.
  - State is centralized in `Store/SocialBatteryStore.swift` (an @MainActor ObservableObject). UI reads state via `@StateObject`/`@ObservedObject` in files under `Views/`.
  - Business logic / models live in `Models/` (notably `Friends.swift`) — the Battery engine is `BatteryEngine.status(for:policy:...)` and uses `FrequencyLimit`, `Availability`, and `ColorCodable`.
  - Authentication is provided by Amplify/Cognito. App config is wired in `social_batteryApp.swift` where `AWSCognitoAuthPlugin` is added and `Amplify.configure` is called with amplify outputs.
  - Persistence: lightweight JSON stored in the app Documents directory. See the `saveURL` in `SocialBatteryStore` (filename: `social_battery.json`).

- Key integration points
  - Amplify: imports and configuration in `social_batteryApp.swift`. ViewModels call `Amplify.Auth` (see `Models/UserViewModel.swift`). Ensure Amplify outputs/config (`amplify_outputs.json`) are available when running.
  - Backend infra: `amplify/backend.ts` (defines `auth` and `data`) and `terraform/` contains provider/infra hints. Changes to backend require using your Amplify/Terraform workflows — there's a helper script at `scripts/init amplify.sh`.

- Project-specific conventions and patterns (follow these exactly)
  - All observable shared state objects are `@MainActor` and use `@Published` properties (e.g., `SocialBatteryStore`, `UserViewModel`). Keep modifications to those objects on the main actor.
  - Models are Codable + Sendable where appropriate. When adding a new property to `Friend`, update the `Snapshot` nested struct and persistence encoder/decoder in `SocialBatteryStore`.
  - Color values are encoded with `ColorCodable` (wrapper around `UIColor` components). Use `friend.color.color` to get a SwiftUI `Color` instance.
  - Business rules live in model types, not in views. Use `BatteryEngine.status(...)` for battery calculations rather than duplicating logic in UI files.

- Common tasks and quick examples
  - Add a friend programmatically: `store.addFriend(name: "Name", color: .red, maxFrequency: .timesPerWeek(2))`.
  - Record a meeting: `store.recordMeeting(with: friend.id, on: Date())` — this updates `friends` and persists to disk.
  - Check a friend's battery: `store.status(for: friend)` (returns `BatteryStatus` with `percent` and `nextRecommendedDate`).

- Build / run / test notes
  - Open the Xcode project or workspace (`social-battery.xcodeproj` / workspace in the repo root) and run on a simulator or device as usual.
  - Amplify must be configured at runtime. If you update Amplify resources, ensure the app has an up-to-date amplify outputs/config before launching.
  - Tests live in `social-batteryTests/` and `social-batteryUITests/`. Run tests from Xcode's Test action, or use `xcodebuild` from CI (replace <SCHEME> and <SIM>):

```bash
# Example (replace scheme and simulator/device):
xcodebuild -project social-battery.xcodeproj -scheme <SCHEME> -destination 'platform=iOS Simulator,name=iPhone 15' test
```

  - Simulator data location: the app persists to the app's Documents folder. To inspect it, use `xcrun simctl get_app_container <device> <bundle-id> data` or view via the simulator's container UI (replace `<bundle-id>` with your app bundle id).

- Where to start when changing behaviour
  - UI changes: `Views/` (ContentView, FriendRowView, ScheduleView, SettingsView). Prefer small view-level updates that call into `SocialBatteryStore` for changes.
  - Business logic: `Models/Friends.swift` (update BatteryEngine / FrequencyLimit / Availability if changing scheduling or battery rules).
  - Persistence: `Store/SocialBatteryStore.swift` — update `Snapshot` and `save/load` logic when schema changes.
  - Auth flows: `Models/UserViewModel.swift` and `social_batteryApp.swift` (Amplify plugin registration).

- Tests and safety checks
  - Add unit tests for deterministic model logic in `Models/` (e.g., BatteryEngine). Keep tests small and deterministic by injecting `Calendar`/`Date` when needed.

- Files to inspect for context
  - App entry: `social-battery/social_batteryApp.swift`
  - State & persistence: `social-battery/Store/SocialBatteryStore.swift`
  - Models & business rules: `social-battery/Models/Friends.swift`, `Models/UserViewModel.swift`
  - Views: `social-battery/Views/` (e.g., `FriendRowView.swift`, `ScheduleView.swift`)
  - Backend infra: `amplify/backend.ts`, `terraform/`

If any of these areas are unclear or you need examples for a specific change (new API, new model field, or adding Amplify features), tell me which area and I'll expand the instructions or update examples.
