# Agent prompt template

A ready-made prompt for AI chats that cannot read the Campus Motion repository.

## When to use it

Agents that work inside the repository (Claude Code, Cursor, Codex, Copilot, Antigravity) read [AGENTS.md](../AGENTS.md) on their own. With them, paste the issue as it is; no prompt is needed.

Use the prompt below only with a chat that has no access to the code, such as a browser chat with no files attached. It gives that chat the project's hard rules. Such a chat cannot see which widgets and services already exist, so it may recreate something that is already there: check its output against [DESIGN.md](DESIGN.md) and [ARCHITECTURE.md](ARCHITECTURE.md) before using it.

## Prompt

Copy everything in the block, then replace the last line with the issue's title and body.

```text
I am working on Campus Motion, a Flutter 3 app (https://github.com/Campus-Motion/mobile-app-flutter).
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
