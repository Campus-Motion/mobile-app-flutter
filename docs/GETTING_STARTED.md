# Getting started

This guide takes you from a fresh clone to a running app and shows how to run the same checks CI runs. It is the practical companion to [ARCHITECTURE.md](ARCHITECTURE.md) (how the app is built) and [../CONTRIBUTING.md](../CONTRIBUTING.md) (how changes land).

## 1. Prerequisites

- **Flutter SDK** on the stable channel (Dart 3.11 or later, as required by `mobile_app/pubspec.yaml`). Check with `flutter --version`.
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
flutter run -d chrome     # web
flutter run               # connected phone, emulator or simulator
```

The app talks to `https://api.campusmotion.ch` (see [API.md](API.md)). In a debug web build, requests go through a CORS proxy so the browser accepts them.

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

These are the four steps CI runs on every pull request (see `.github/workflows/ci.yml`). Run them before you push:

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
| Web build shows CORS or network errors | Use mock mode, or check that `https://api.campusmotion.ch` is reachable. |
| Format check fails in CI but not locally | Run `dart format .` from `mobile_app/` and commit the result. |
| `coverage/lcov.info not found` | Run `flutter test --coverage` before the coverage script. |

## 6. Where to go next

- [FUNCTIONAL_OVERVIEW.md](FUNCTIONAL_OVERVIEW.md) to learn what the app does.
- [ARCHITECTURE.md](ARCHITECTURE.md) before writing code.
- [DESIGN.md](DESIGN.md) before building a screen.
- [../CONTRIBUTING.md](../CONTRIBUTING.md) before opening a pull request.
