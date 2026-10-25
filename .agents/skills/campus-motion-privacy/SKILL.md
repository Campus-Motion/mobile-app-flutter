---
name: campus-motion-privacy
description: Implement and review Campus Motion changes that touch personal or health data under GDPR, including weight, height and birth date, consent, the sensitive_data payload, activity visibility, data export, health or account deletion, retention, location, other users' profiles and followers, and any new network destination or package. Use for changes to HealthData, UserService, ActivityService, profile and settings screens, or anything that collects, displays or shares user data.
---

# Campus Motion privacy

Keep every privacy promise in `docs/FUNCTIONAL_OVERVIEW.md` section 5 true after the change.

## Required context

Read `AGENTS.md` section 8 and `docs/ARCHITECTURE.md` section 6. Then read `lib/models/health.dart`, `lib/services/user_service.dart`, `lib/screens/app/profile/edit.dart` and `lib/screens/app/profile/settings.dart`, plus whatever the change touches.

## Workflow

### 1. Classify the data

For each field the change reads, stores, sends or shows, decide:

- **Health (special category):** weight, height, birth date, and anything derived from them or from workouts that reveals health. Needs explicit consent.
- **Personal:** username, email, photo, preferences, activities, follows, location.
- **Other users' data:** anything about someone other than the signed-in user.

### 2. Check each invariant

| Invariant | Check |
|---|---|
| Consent | Health data is collected and sent only when consent is given (`consent_given_at` set). Withdrawing consent calls `UserService.deleteHealth()`. There is no path that saves health fields without the checkbox. |
| Encapsulation | Health metrics go only inside `sensitive_data` with `client_key_version` (`HealthData.toJson`). They do not appear in other payloads, logs, `debugPrint` output, analytics or error messages. |
| Private by default | New activities and any new user-generated content default to private (`is_public: false`). Making something public is an explicit user action. |
| Minimisation | Only the fields the feature needs are fetched and shown. Another user's profile shows only what they made public. |
| Erasure | `deleteHealth()` and `deleteMe()` still work and still reach the backend. New personal data is deleted with the account. |
| Portability | `_exportData()` in settings includes any new personal data. |
| Retention | Health records keep `retain_until`. |
| No third parties | No new host besides `api.campusmotion.ch` (and the debug-only CORS proxy). No Firebase, analytics, crash-reporting or tracking package. No new package without user approval. |
| Transparency | If the change collects something new, the privacy policy text in `PrivacyPolicyDialog` and the consent wording say so. |
| Secrets | No tokens, keys or credentials in code, tests or mock data. Mock data uses invented people. |

### 3. Test

- Model: `HealthData` round trip keeps metrics inside `sensitive_data`.
- Flow: in mock mode, saving without consent sends nothing; withdrawing consent deletes.
- Default: a newly created activity or content item is private.
- Export: new fields appear in the export.

Run the targeted tests, then the four CI checks from `mobile_app/`.

### 4. Report

In the hand-off, state which data categories the change touches and confirm each invariant above, or name the one that needs a team decision.

## Reject a change that

- stores, sends or displays health data without a consent check;
- logs or prints personal or health data;
- makes new content public by default;
- removes or bypasses deletion or export;
- adds a network destination, SDK or package that receives user data;
- shows another user's non-public data.
