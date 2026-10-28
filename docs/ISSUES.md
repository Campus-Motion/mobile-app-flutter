# Writing issues

An issue is a work order. Someone who has never seen the code, or an AI agent with nothing but the issue text, should be able to pick it up, build the right thing, and know when it is done. This page defines the one format every issue follows.

On GitHub, **New issue** opens a form for each type below (`.github/ISSUE_TEMPLATE/`). The forms produce exactly the structure described here. When you create an issue another way (`gh issue create`, an AI agent, the API), reproduce the same headings in the same order. Agents must follow the [`campus-motion-issue-writing`](../.claude/skills/campus-motion-issue-writing/SKILL.md) skill.

## Rules for every issue

1. **No emoji.** Not in titles, headings, bullets or labels. Headings are plain words.
2. **One issue, one pull request.** If it needs more than one PR, it is an epic with sub-issues.
3. **Size L means split it.** An L issue is acceptable only for a mechanical change that cannot be divided; otherwise turn it into smaller issues.
4. **Point at the code.** Name files, classes and methods in backticks with their path (`lib/screens/app/home/index.dart`, `EventService.getEvents`). Describe what happens today before what should happen.
5. **Acceptance criteria are checkable.** Each one is a checkbox a reviewer can verify by reading the diff, running the app or running a test. "Works well" is not a criterion; "past events never appear after a pull-to-refresh" is.
6. **Say what is out of scope.** It stops a contributor or an agent from refactoring half the app.
7. **Link dependencies with issue numbers**, never with "the Home issue" or "the previous one".
8. **Name what to reuse.** "What to build" (or "Target") lists the existing widgets, services and helpers the implementer should build on, so the pull request stays small.
9. **Respect the contract.** An issue never asks for something that breaks [AGENTS.md](../AGENTS.md): no Firebase, no HTTP in screens, no health data without consent, no new state library.

## Title

```
<type>(<scope>): <imperative summary, lower case, no final period>
```

| Type | Use for | Label |
|---|---|---|
| `feat` | A new user-visible capability | `enhancement` |
| `fix` | Something that behaves wrongly | `bug` |
| `refactor` | Same behaviour, better code | `refactor` |
| `chore` | Tooling, CI, dependencies, repository settings | `ci` when it is CI |
| `docs` | Documentation only | `documentation` |
| `test` | Tests only | |
| `spike` | Research that answers a question; no production code | `spike` |
| `epic` | A goal split into sub-issues (`epic: <summary>`, no scope) | `epic` |

The scope is the area of the app: `home`, `activity`, `events`, `social`, `profile`, `auth`, `widgets`, `nav`, `routes`, `services`, `models`, `ci`, `docs`, or a new feature area such as `orgs` or `feed`.

Good: `fix(home): keep the upcoming-events filter on pull-to-refresh`
Bad: `Home bug`, `Fix: Pull to refresh!!`, `feat: stuff for events`

## Labels

Every issue carries a **type** label (table above), one **size** label and, once triaged, one **priority** label.

| Size | Meaning |
|---|---|
| `size: XS` | Under two hours. A small fix plus a test. |
| `size: S` | About half a day. |
| `size: M` | One to two days. |
| `size: L` | Three days or more. Split it if you can. |

| Priority | Meaning |
|---|---|
| `priority: P0` | Blocks other work or users. Do first. |
| `priority: P1` | Planned for the current iteration. |
| `priority: P2` | Worth doing; no deadline. |

Optional: `good first issue` (small, well-located, no design decision left), `help wanted`, `needs: backend` (cannot be finished without a backend change; link the backend issue).

## Sections by type

Headings are `###` (that is what the GitHub forms produce), in this order. Optional sections are marked; leave them out rather than writing "N/A". Feature, bug, refactor and task issues end with a `### Size` section (XS, S, M or L, as defined above); spikes use their timebox instead, and an epic's size is the sum of its sub-issues.

### Feature (`feat`)

| Section | Content |
|---|---|
| Goal | One or two sentences: the outcome for the user. |
| Today | What exists now, with file paths. What is missing. |
| What to build | The concrete changes: screens, widgets, services, models, routes. Reuse existing widgets by name. |
| Design | Optional. Figma link or screenshot. |
| Acceptance criteria | Checkboxes. |
| Out of scope | What not to do. |
| Dependencies | Optional. `Part of #N. Blocked by #N. Blocks #N. Related: #N.` |
| Open questions | Optional. Decisions needed before starting, and who decides. |

### Bug (`fix`)

| Section | Content |
|---|---|
| Summary | What is wrong, in one sentence. |
| Steps to reproduce | Numbered steps, including whether mock mode was on. |
| Expected behaviour | |
| Actual behaviour | Include error text or a screenshot. |
| Where | Optional. Suspected file, method or line. |
| Environment | Platform (web, Android, iOS), mock or real backend, branch or commit. |
| Acceptance criteria | Must include a regression test, or an explanation of why one is not possible. |
| Out of scope | |

### Refactor (`refactor`)

| Section | Content |
|---|---|
| Goal | What gets better, and the promise that behaviour does not change. |
| Problems today | The concrete issues, with file paths and line counts. |
| Target | The structure after the change. |
| Acceptance criteria | Must include "behaviour unchanged" with how it was checked. |
| Out of scope | |

### Task (`chore`, `docs`, `test`)

| Section | Content |
|---|---|
| Goal | |
| What to do | |
| Acceptance criteria | |
| Out of scope | Optional. |

### Spike (`spike`)

| Section | Content |
|---|---|
| Question | What we need to find out, as numbered questions. |
| Why it matters | Which decision or issues depend on the answer. |
| Deliverable | Usually a `docs/<TOPIC>.md` file, a decision, and follow-up issues. |
| Timebox | The maximum time to spend. |
| Acceptance criteria | Every question answered with sources; decision recorded. |
| Out of scope | Usually "writing production code". |

### Epic (`epic`)

| Section | Content |
|---|---|
| Goal | The outcome when every sub-issue is closed. |
| Sub-issues | A task list of issue numbers: `- [ ] #22 Events feed screen`. |
| Sequencing | Which sub-issues block which: `#17 then #22 then #23`. |
| Open questions | Optional. |
| Out of scope | |

## Acceptance criteria that always apply

These do not need repeating in every issue; CI and review enforce them:

- `dart format`, `flutter analyze --fatal-infos`, `flutter test` and the coverage gate pass.
- New screens are in `MasterContainer` and registered in `AppRoutes`.
- New shared widgets have a widget test in `test/widgets/`.
- New or changed endpoints have a `MockDataService` handler.

Add a criterion only when it is specific to the issue.

## Example

Title: `fix(home): keep the upcoming-events filter on pull-to-refresh`
Labels: `bug`, `size: XS`, `good first issue`

```markdown
### Summary

After a pull-to-refresh, the Home events carousel can show events that have already happened.

### Steps to reproduce

1. Start the app in mock mode and open Home.
2. Pull down to refresh.
3. Past events appear in "Upcoming Events".

### Expected behaviour

Refresh shows the same upcoming-only events as the first load.

### Actual behaviour

Refresh calls `getEvents(limit: 5)` without the `after` filter, so past events come back.

### Where

`lib/screens/app/home/index.dart`: `initState` passes `after: DateTime.now()`, `_refreshNews` does not.

### Environment

Any platform, mock or real backend, `main`.

### Acceptance criteria

- [ ] First load and refresh use one helper, so the queries cannot drift apart again
- [ ] The `after` timestamp is computed at refresh time
- [ ] A test in mock mode shows past events are excluded after a refresh

### Out of scope

Restyling event cards. Pagination. Backend changes to `/events`.

### Size

XS (under two hours)
```
