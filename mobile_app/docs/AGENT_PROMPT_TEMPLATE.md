# AI Agent Prompt Template for Campus Motion

Copy and paste the prompt below directly into your AI coding tool (Claude Code, Cursor Composer, Antigravity, ChatGPT, or GitHub Copilot) alongside your GitHub issue.

---

### Copy-Paste Prompt:

```markdown
You are a senior Flutter engineer working on the Campus Motion application.
Please read and strictly follow the repository operating contract in `AGENTS.md`.

### Hard Architectural Invariants:
1. Wrap any new or updated top-level screen in `MasterContainer` (`lib/widgets/master_container.dart`) to ensure the 450px responsive width constraint.
2. Centralize any new route in `AppRoutes` (`lib/config/routes.dart`).
3. Keep clean layering: NEVER make direct `http` calls inside UI screens. Delegate all network operations to Domain Services in `lib/services/`.
4. Our backend is the custom REST API at `https://api.campusmotion.ch` via `ApiService`. NEVER import or use Firebase.
5. Strictly respect GDPR: Sensitive health metrics (weight, height, age) require explicit opt-in consent and must never be leaked. New activities must default to `is_public: false`.
6. Guard async gaps: Always add `if (!mounted) return;` after `await` before touching `BuildContext`.
7. Modern Flutter 3 APIs: Use `.withValues(alpha: ...)` instead of `withOpacity()`, and `SharePlus.instance.share(...)` instead of `Share.share(...)`.
8. Write/update tests in `test/` and run `flutter analyze` and `flutter test` to verify everything passes with 0 errors.

### Here is the GitHub Issue to implement:
<PASTE_GITHUB_ISSUE_TITLE_AND_BODY_HERE>

Please implement the solution, verify it with `flutter analyze` and `flutter test`, and output a clean Pull Request summary explaining:
1. What was implemented and why.
2. Which architectural layers were modified.
3. Verification results.
```
