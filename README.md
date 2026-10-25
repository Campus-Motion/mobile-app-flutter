# Campus Motion

**Campus Motion** is the sports and health community app for students and staff at EPFL and UNIL.

It brings campus members together around a connected running trail, scheduled sporting events, personal activity tracking and a social feed. Health data stays private: the app talks only to Campus Motion's own GDPR-compliant REST API, never to a third-party cloud, and every sensitive field needs explicit consent. The app is built with Flutter 3 and runs on Android, iOS, the web and desktop.

## Documentation hub

This README is the entry point. Each document below has one job.

| Document | What it covers |
|---|---|
| [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md) | From a fresh clone to a running app: prerequisites, mock mode, running the checks. |
| [docs/FUNCTIONAL_OVERVIEW.md](docs/FUNCTIONAL_OVERVIEW.md) | What the product does and for whom: users, tabs, privacy promise, current status (non-technical). |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the app is built: tech stack, layers, repository layout, routing, services, mock mode, privacy architecture. |
| [docs/DESIGN.md](docs/DESIGN.md) | How the interface looks: colour tokens, spacing, the shared widget catalog, copy rules, accessibility floor. |
| [docs/API.md](docs/API.md) | The backend contract the app consumes: base URL, auth, response envelope, every endpoint and the service that calls it. |
| [docs/ISSUES.md](docs/ISSUES.md) | How to write an issue: types, title format, labels, required sections. |
| [docs/STUDENT_WORKFLOW_GUIDE.md](docs/STUDENT_WORKFLOW_GUIDE.md) | Step-by-step guide for new contributors working with an AI coding agent. |
| [docs/AGENT_PROMPT_TEMPLATE.md](docs/AGENT_PROMPT_TEMPLATE.md) | Fallback prompt for AI chats that cannot read the repository. |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Branch and PR workflow, quality gates, testing and documentation expectations. |
| [AGENTS.md](AGENTS.md) | Operating contract for AI coding agents. |
| [CLAUDE.md](CLAUDE.md) | Claude Code specifics (commands and slash workflows). |

## New here? Read in this order

1. [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md): get the app running.
2. [docs/FUNCTIONAL_OVERVIEW.md](docs/FUNCTIONAL_OVERVIEW.md): understand what Campus Motion does.
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): learn where code goes and why.
4. [docs/DESIGN.md](docs/DESIGN.md): before you build a screen.
5. [CONTRIBUTING.md](CONTRIBUTING.md): before you open your first PR.
6. [docs/STUDENT_WORKFLOW_GUIDE.md](docs/STUDENT_WORKFLOW_GUIDE.md): if you work with an AI agent.

## Quick reference

All Flutter commands run from `mobile_app/`. Full details in [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md).

```bash
cd mobile_app
flutter pub get
flutter run -d chrome --dart-define=MOCK_API=true   # run without the backend
```

The checks CI runs on every pull request:

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos
flutter test --coverage
dart run tool/check_coverage.dart
```

## Repository map

| Path | Contents |
|---|---|
| [`mobile_app/lib/screens/`](mobile_app/lib/screens) | Screens: compose widgets and bind state, nothing else. |
| [`mobile_app/lib/widgets/`](mobile_app/lib/widgets) | Shared UI components (`MasterContainer`, `AppCard`, `AppButton`, ...). |
| [`mobile_app/lib/services/`](mobile_app/lib/services) | Singleton services: all network I/O, plus the offline mock backend. |
| [`mobile_app/lib/models/`](mobile_app/lib/models) | Typed data models with JSON serialization. |
| [`mobile_app/lib/config/routes.dart`](mobile_app/lib/config/routes.dart) | `AppRoutes`, the single route table. |
| [`mobile_app/lib/constants/colors.dart`](mobile_app/lib/constants/colors.dart) | `AppColors`, the design tokens. |
| [`mobile_app/test/`](mobile_app/test) | Unit and widget tests. |
| [`mobile_app/tool/`](mobile_app/tool) | Repository tooling (coverage gate). |
| [`docs/`](docs) | Documentation. |
| [`.github/`](.github) | CI workflow, issue forms and the pull request template. |
| [`.claude/skills/`](.claude/skills), [`.agents/skills/`](.agents/skills) | Project skills for AI agents (two mirrored copies). |
