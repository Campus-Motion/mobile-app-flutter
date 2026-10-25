# Agent prompt template

**You usually do not need this.** Claude Code, Cursor, Codex, Copilot and Antigravity read [AGENTS.md](../AGENTS.md) automatically when they work inside the repository. Paste the raw issue and they follow the contract.

Use the prompt below only with an AI chat that cannot see the repository (for example a browser chat with no files attached). It summarizes the hard rules; the agent still cannot check existing widgets or services, so review its output carefully against [DESIGN.md](DESIGN.md) and [ARCHITECTURE.md](ARCHITECTURE.md).

```text
I am working on Campus Motion, a Flutter 3 app (https://github.com/Campus-Motion/mobile-app-v2).
Follow these project rules:
- Screens live in lib/screens/ and only compose widgets and hold state. Wrap every screen in MasterContainer.
- Reusable UI lives in lib/widgets/, one widget per file. Reuse AppCard, AppButton, StatItem, ActivityCard,
  EventPreviewCard, NewsCard and SectionHeader before creating anything new.
- Colours come only from AppColors (lib/constants/colors.dart). No Color(0x...) or Colors.* literals.
- Register every screen in AppRoutes (lib/config/routes.dart) and navigate with Navigator.pushNamed.
- Network calls only in singleton services in lib/services/, through ApiService. Never call http from a screen.
- Backend is the Campus Motion REST API at https://api.campusmotion.ch. Never use Firebase.
- Add a MockDataService handler for any new or changed endpoint.
- Weight, height and birth date need explicit consent (GDPR Article 9). New activities default to is_public: false.
- After every await, check `if (!mounted) return;` before using BuildContext.
- Use .withValues(alpha: ...) and SharePlus.instance.share(...).
- Add widget tests in test/widgets/ for new widgets and tests for new service methods.
- No emoji in code, UI text, commit messages or PR descriptions.

Here is the issue:
<PASTE THE ISSUE TITLE AND BODY HERE>
```
