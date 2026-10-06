# Zero-Prompt Reference

> [!NOTE]
> **No prompt engineering is required!**
> If you are using **Cursor**, **Claude Code**, or **Antigravity**, you do **not** need to paste any special prompt. The agent reads `AGENTS.md` automatically. Simply copy and paste the raw GitHub issue title and description into your chat.

---

### Fallback Prompt (Only for Web-Only AI without Codebase Access)
If you are using an external AI chat interface that has no direct access to the repository files (e.g., standard browser ChatGPT or Claude.ai without file attachments):

```text
I am working on the Campus Motion Flutter app (https://github.com/Campus-Motion/mobile-app-v2).
Follow our repository contract in AGENTS.md:
- Wrap top-level screens in MasterContainer (450px responsive width constraint).
- Register routes in AppRoutes (lib/config/routes.dart).
- Never call http from UI code; use singleton Domain Services (lib/services/).
- Backend is custom REST API at https://api.campusmotion.ch. Never use Firebase.
- Respect GDPR Article 9 explicit consent for health data.
- Always check 'if (!mounted) return;' across async gaps.
- Use Flutter 3 APIs (.withValues(alpha: ...)).

Here is my GitHub issue:
<PASTE ISSUE HERE>
```
