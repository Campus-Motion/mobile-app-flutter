# Campus Motion - Claude Code guidelines

[AGENTS.md](AGENTS.md) is the operating contract and applies in full. Read it completely before doing any work. This file only adds Claude Code specifics.

## Default action on a pasted issue or screenshot

When the user pastes a GitHub issue, an issue URL or a Figma screenshot, with or without other words, do not ask for rules or architecture. Run the five-phase pipeline in [AGENTS.md section 5](AGENTS.md#5-zero-prompt-issue-and-screenshot-ingestion): decompose, inventory `lib/widgets/`, implement inside `MasterContainer` with `AppColors` and `AppRoutes`, verify, hand off with a branch name, commit message and PR description.

## Skills

Project skills are in `.claude/skills/` (mirrored in `.agents/skills/`; keep both identical):

- `campus-motion-ui-quality`: screens, widgets, screenshot-to-code.
- `campus-motion-privacy`: health data, consent, export, deletion, other users' data.
- `campus-motion-issue-writing`: drafting or editing GitHub issues and epics.

## Commands

Run from `mobile_app/`.

- Install: `flutter pub get`
- Format: `dart format .`
- Format check: `dart format --output=none --set-exit-if-changed .`
- Analyze: `flutter analyze --fatal-infos`
- Tests: `flutter test` (one file: `flutter test test/<path>_test.dart`)
- Coverage: `flutter test --coverage` then `dart run tool/check_coverage.dart`
- Run offline on web: `flutter run -d chrome --dart-define=MOCK_API=true`

Do not start `flutter run` unless the user asks; prefer the checks above.

## Slash workflows

### `/issue-to-pr`

The pipeline above.

### `/fix-ci`

1. `gh pr checks`, then `gh run view --log-failed`.
2. Fix the source code locally. Never edit tests, `analysis_options.yaml`, `tool/check_coverage.dart` or `.github/workflows/` to pass.
3. Re-run the four CI commands, commit, push.
4. Stop after 3 to 4 iterations and report.

### `/correct-pr`

1. `gh pr view --comments` (plus inline comments through `gh api`).
2. Apply the requested changes within the architecture.
3. Re-run the checks, commit, push, and summarize each comment's resolution.

## Preferences

- Keep solutions concise and simple; propose the simpler option when one exists.
- If a request is too large for one coherent change, say so and propose a split.
- No emoji anywhere: code, UI text, commits, PRs, issues, docs.
