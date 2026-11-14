# Getting started

This guide takes you from a fresh clone to a running app and shows how to run the same checks CI runs. It is the practical companion to [ARCHITECTURE.md](ARCHITECTURE.md) (how the app is built) and [../CONTRIBUTING.md](../CONTRIBUTING.md) (how changes land).

## 1. Prerequisites

- **Flutter SDK** `3.47.6` on the stable channel (pinned in `mobile_app/pubspec.yaml` and CI; Dart 3.11.5 or later). Check with `flutter --version`.
- **Git**.
- **Chrome**, to run the web build, which is the fastest way to try the app.
- Optional: **Java 17** and Android Studio for Android builds, Xcode (macOS only) for iOS builds.
- An editor with the Flutter and Dart extensions: VS Code, Cursor or Android Studio.

Run `flutter doctor` and fix anything it reports for the platforms you plan to use.

## 2. Clone and install

```bash
git clone https://github.com/Campus-Motion/mobile-app-v2.git
cd mobile-app-v2/mobile_app
flutter pub get
```

The repository root holds the documentation and agent instructions. The Flutter project lives in `mobile_app/`, and **every Flutter command runs from there**.

Open the **repository root** (not `mobile_app/`) in your editor, so the editor and any AI agent pick up `AGENTS.md`, `CLAUDE.md` and `.cursor/rules/`. The VS Code launch configurations in `.vscode/launch.json` already point at `mobile_app/`.

## 3. Run the app

### Against the real backend

```bash
flutter run -d chrome --web-port 8080   # web
flutter run               # connected phone, emulator or simulator
```

The app talks to `https://api.campusmotion.ch` (see [API.md](API.md)). On web, the browser only accepts the responses if the backend allows the page origin, so always run on port 8080 (`http://localhost:8080` must be in the backend CORS allow-list). Phones, emulators and simulators are not affected.

### Without the backend (mock mode)

You do not need backend access to work on most features. `MockDataService` (`lib/services/mock_data_service.dart`) is an in-memory backend that answers every endpoint the app uses with realistic data. There are three ways in:

1. **Demo button.** Tap **Demo Mode (Offline Bypass)** on the welcome or sign-in screen. It switches the app to mock mode and signs you in as a demo user.
2. **Launch flag.** Start the whole session in mock mode:

   ```bash
   flutter run -d chrome --dart-define=MOCK_API=true
   ```

3. **Automatic fallback.** In debug builds only, if the real backend is unreachable or returns a 5xx error, `ApiService` falls back to mock data for that request and logs a `[ApiService]` line in the console.

Mock data is for development and tests. Release builds never fall back to it.

## 4. Run the checks

Run these four checks before you push. CI runs the same checks plus the web and Android platform builds on every pull request (see `.github/workflows/ci.yml`):

```bash
# 1. Formatting: fails if any file is not formatted
dart format --output=none --set-exit-if-changed .
#    fix with:
dart format .

# 2. Static analysis: errors, warnings and infos all fail
flutter analyze --fatal-infos

# 3. Tests, with coverage written to coverage/lcov.info
flutter test --coverage

# 4. Coverage floor (15% line coverage today)
dart run tool/check_coverage.dart

# 5. Platform builds (run in CI; run locally when verifying web or Android builds)
flutter build web --release --dart-define=MOCK_API=true
flutter build apk --debug
```

To run one test file while you work:

```bash
flutter test test/widgets/news_card_test.dart
```

## 5. Common problems

| Symptom | Fix |
|---|---|
| `flutter: command not found` | Add the Flutter `bin/` directory to your `PATH`, then reopen the terminal. |
| `pubspec.yaml not found` | You are at the repository root. `cd mobile_app` first. |
| Web build shows CORS or network errors | Run with `--web-port 8080`, use mock mode, or check that `https://api.campusmotion.ch` is reachable. |
| Format check fails in CI but not locally | Run `dart format .` from `mobile_app/` and commit the result. |
| `coverage/lcov.info not found` | Run `flutter test --coverage` before the coverage script. |

## 6. Where to go next

- [FUNCTIONAL_OVERVIEW.md](FUNCTIONAL_OVERVIEW.md) to learn what the app does.
- [ARCHITECTURE.md](ARCHITECTURE.md) before writing code.
- [DESIGN.md](DESIGN.md) before building a screen.
- [../CONTRIBUTING.md](../CONTRIBUTING.md) before opening a pull request.

## 7. Test the personal heatmap

The heatmap changes span three repositories. Keep the matching local feature
branches together; publishing a cloud environment does not push them to GitHub
or deploy the backend.

### Automated checks

From `Trail-parcours/`:

```sh
.venv/bin/python -m pip install -r requirements-dev.txt
.venv/bin/python -m pytest -q
```

These test real FIT decoding, waypoint JSON, PNG/HTML rendering, invalid inputs,
limits and the shared rendering lock.

From `Back_End_App/api_v1/`:

```sh
npm ci
npm run build
npm test -- --runInBand test/activities/heatmaps.spec.ts
```

These cover JWT authentication, owner-scoped queries, 204 for empty routes,
limits, renderer failures and `Cache-Control: no-store`.

From `mobile-app-flutter/mobile_app/`:

```sh
flutter pub get
flutter test test/services/heatmap_test.dart test/widgets/heatmap_view_test.dart test/screens/heatmap_screen_test.dart
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed .
flutter test --coverage
dart run tool/check_coverage.dart
```

The focused tests cover response parsing, the narrow-screen viewer, loading,
empty data, retry after failure and leaving during an unfinished request.

### Try the interface without a server

```sh
flutter run -d chrome --web-port 8080 --dart-define=MOCK_API=true
```

1. Select **Demo Mode (Offline Bypass)** on the welcome screen.
2. Open **Sport**, then **My heatmap**.
3. Confirm a synthetic route appears with its activity count and geographic bounds.
4. Zoom, pan, select **Refresh**, then use **Back** to return to Sport.

This checks the interface only. It does not call Python, read real activity data
or demonstrate authentication. No street-map background is expected.

### Test the real service chain

Use a test deployment of the matching backend and renderer first (see
`Back_End_App/api_v1/README.md`). The app currently targets
`https://api.campusmotion.ch`; mock mode does not test that server.

With dedicated test accounts and synthetic GPS data:

| Case | Expected result |
|---|---|
| No Bearer token on `GET /activities/heatmap` | 401 |
| Signed-in user with no GPS routes | 204; app shows "No GPS routes yet" |
| Private activity created with `POST /activities`, then at least two timestamped moving GPS points added using `POST /activities/{id}/waypoints` | 200 with PNG `image`, geographic `bounds` and activity count |
| Another user's public activity | Excluded from the personal heatmap |
| Delete the test activity and refresh | Deleted route is absent; 204 if no other routes remain |
| Renderer stopped in the test deployment | 503; app offers retry |

Do not enter real GPS tracks or production credentials into tests. The renderer
accepts coordinates in degrees and ISO timestamps; sample points five seconds
apart near latitude 46.5, with longitude increasing by 0.0001 each point, provide
movement accepted by the filters. Merely logging an activity title does not
create GPS waypoints.

When checking failures in the app against the real API, use a release build
without `MOCK_API=true`: debug builds automatically substitute mock data for
network failures and 5xx responses. This existing fallback can conceal a real
renderer outage during manual testing.
