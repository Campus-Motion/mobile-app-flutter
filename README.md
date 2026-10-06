# Campus Motion - Mobile App (v2)

Welcome to the **Campus Motion** mobile application repository!

Campus Motion is a connected sports and health community application built for students and staff at EPFL and UNIL. The app connects campus members around a physical connected trail on campus, scheduled sporting events, personal activity tracking, and social interactions, with a core commitment to student health data privacy and European General Data Protection Regulation (GDPR) compliance.

---

## 🚀 Quick Navigation & Sources of Truth

- **AI Agent Operating Contract**: [`AGENTS.md`](AGENTS.md) *(Authoritative repository rules for AI coding assistants)*
- **Claude Code Guide**: [`CLAUDE.md`](CLAUDE.md)
- **Student Onboarding & Workflow Guide**: [`docs/STUDENT_WORKFLOW_GUIDE.md`](docs/STUDENT_WORKFLOW_GUIDE.md)
- **Agent Copy-Paste Prompt Template**: [`docs/AGENT_PROMPT_TEMPLATE.md`](docs/AGENT_PROMPT_TEMPLATE.md)
- **Architecture & Tech Tree Decisions**: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)
- **Flutter Application Source**: [`mobile_app/`](mobile_app/)

---

## 🛠 Tech Stack Snapshot

- **Framework**: Flutter 3 (Dart 3)
- **Target Platforms**: Android, iOS, Web, Linux, macOS, Windows
- **Design System**: Material Design with custom peach/terracotta palette (`AppColors.primary = 0xFFDE7356`), responsive mobile shell (`MasterContainer` capped at 450px width)
- **Networking**: Custom REST backend at `https://api.campusmotion.ch` with Bearer JWT authentication (No Firebase)
- **Compliance**: GDPR Article 9 explicit opt-in consent for sensitive health metrics, right to erasure, and JSON data portability export

---

## 💻 Developer Getting Started

### 1. Prerequisites
- Flutter SDK 3.44+ / Dart 3.12+ installed
- Java 17+ (for Android builds)
- VS Code or Cursor with Flutter & Dart extensions

### 2. Setup
```bash
# Navigate to the Flutter app directory
cd mobile_app

# Install dependencies
flutter pub get

# Check code quality
flutter analyze

# Run tests
flutter test

# Run app in Chrome (Web)
flutter run -d chrome

# Run app on connected phone or simulator
flutter run
```

---

## 🤖 AI-Assisted Development Workflow

Campus Motion is designed to empower students of all skill levels to contribute using AI coding agents (Cursor, Claude Code, Antigravity, Copilot, ChatGPT).

### How to Work on an Issue:
1. **Branch**: Create a branch `git checkout -b feat/your-feature-name` from `main`.
2. **Prompt**: Copy the prompt from [`docs/AGENT_PROMPT_TEMPLATE.md`](docs/AGENT_PROMPT_TEMPLATE.md) and paste it into your AI assistant with the GitHub issue description.
3. **Verify**: Run `flutter analyze` and `flutter test`. Ensure zero errors.
4. **Pull Request**: Open a PR. GitHub Actions CI will automatically verify your code.
