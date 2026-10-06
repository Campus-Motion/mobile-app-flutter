# Campus Motion - Claude Code Guidelines

This document outlines commands, architectural boundaries, and automated workflows for Claude Code working on the Campus Motion Flutter repository.

---

## Zero-Prompt & Screenshot Ingestion (Default Action)

When the user provides a raw GitHub issue or **drops a Figma screenshot / mockup**:
- **Do not ask for rules or architecture.**
- Automatically execute the implementation workflow according to `AGENTS.md`.
- **Component-First Extraction**: Deconstruct the screenshot into atomic UI components.
- **Check Reusable Library**: Check `lib/widgets/` first (`AppCard`, `AppButton`, `StatItem`, `ActivityCard`). Reuse existing primitives.
- **Separate Component Management**: If the screen introduces a new visual component, extract it into `lib/widgets/<name>.dart`. Do NOT write monolithic, inline styled containers in screen files.
- **Design Tokens**: Map all colors to `AppColors` (`lib/constants/colors.dart`).
- Wrap top-level screens in `MasterContainer` (450px max width).
- Route via `AppRoutes` in `lib/config/routes.dart`.
- Verify with `flutter analyze` and `flutter test`.
- Conclude with git branch/commit commands and the PR description.

---

## Commands

All commands are run from the Flutter project directory: `mobile_app/` (or relative path `mobile-app-flutter/mobile-app-v2/mobile_app/`).

- **Install Dependencies**: `flutter pub get`
- **Static Analysis**: `flutter analyze`
- **Run All Tests**: `flutter test`
- **Run Specific Test**: `flutter test test/<test_name>.dart`
- **Run App (Web)**: `flutter run -d chrome`
- **Run App (Mobile)**: `flutter run`

---

## Architectural Invariants

1. **Screen Shell**: Every top-level screen **must** be wrapped in `MasterContainer` (`lib/widgets/master_container.dart`). This enforces our responsive 450px maximum width constraint and safe-area margins.
2. **UI Component Separation**: Screens in `lib/screens/` must only compose widgets and bind state. Shared/visual primitives must live in `lib/widgets/`.
3. **Bottom Navigation**: Use `CampusMotionBottomBar` (`lib/widgets/bottom_bar.dart`) for main tabs (0: Home, 1: Sport, 2: Social, 3: Profile).
4. **Routes**: All screens must be registered in `AppRoutes` (`lib/config/routes.dart`). Never use untyped, inline anonymous `MaterialPageRoute` calls for primary app navigation.
5. **Clean Layering**: UI screens **must never** invoke `http` directly. Network operations belong exclusively in `lib/services/` (which use singleton `ApiService`).
6. **No Firebase**: Campus Motion communicates with its custom GDPR-compliant REST API at `https://api.campusmotion.ch`. Never re-introduce Firebase.
7. **GDPR Compliance**: Always respect Article 9 explicit opt-in consent for sensitive health metrics (weight, height, age). Never collect health data without consent.
8. **Async Context Guarding**: Always check `if (!mounted) return;` after an `await` before touching `BuildContext`.
9. **Modern Flutter 3.x APIs**: Use `.withValues(alpha: ...)` instead of deprecated `.withOpacity()`, and `SharePlus.instance.share()` instead of deprecated `Share.share()`.

---

## Automated Workflows

### Raw Issue / Figma Screenshot Paste (`/issue-to-pr`)
Execute this workflow when given a GitHub issue or Figma design:
1. Break down the design into reusable components in `lib/widgets/` and layers (`lib/models/`, `lib/services/`, `lib/screens/`, `lib/config/routes.dart`).
2. Implement components in `lib/widgets/` and compose screen in `lib/screens/` inside `MasterContainer`.
3. Verify by running `flutter analyze` and `flutter test`.
4. Output a summary ready to be pasted into a Pull Request description.

### `/fix-ci`
Execute this when CI fails on a PR:
1. Inspect failing checks: `gh pr checks`
2. Download failed logs: `gh run view --log-failed`
3. Correct the source code locally.
4. **Hard Constraint**: Never weaken `analysis_options.yaml` or alter test assertions merely to pass. Fix the source code.
5. Verify locally using `flutter analyze` and `flutter test`.
6. Push updates up to a maximum of 3-4 loop iterations.

### `/correct-pr`
Execute this to address PR review comments:
1. Fetch review comments: `gh pr view --comments`
2. Implement requested refactors and fixes while respecting component reuse and architectural layering.
3. Verify locally: `flutter analyze` and `flutter test`.
4. Commit and push the updates.
