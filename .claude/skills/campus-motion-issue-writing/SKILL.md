---
name: campus-motion-issue-writing
description: Draft, create, split or rewrite Campus Motion GitHub issues and epics in the project's single format (Conventional title, fixed section headings per type, checkable acceptance criteria, out of scope, size and priority labels, no emoji). Use whenever asked to write an issue, file a bug, plan work as issues, break an epic into sub-issues, or clean up existing issues.
---

# Campus Motion issue writing

Produce issues that a student or an agent with no other context can implement correctly, and that all look the same.

## Required context

Read `docs/ISSUES.md` completely; it is the specification and wins over this file. Read the code the issue is about so the issue names real files, classes and methods. Check open issues (`gh issue list --limit 100`) for duplicates and for numbers to link.

## Workflow

### 1. Classify

Pick exactly one type: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `spike` or `epic`. If the work needs more than one pull request, it is an epic plus sub-issues. If it is size L and can be divided, divide it.

### 2. Investigate before writing

- Locate the code involved and describe today's behaviour with paths in backticks.
- For a bug, reproduce it (mock mode: `flutter run -d chrome --dart-define=MOCK_API=true`) or state that it was found by reading the code.
- Note which existing widgets and services the implementer should reuse (catalog in `docs/DESIGN.md`).
- Check the request against `AGENTS.md`. Never write an issue that asks for Firebase, HTTP in screens, health data without consent, or a new state library.

### 3. Write

- Title: `<type>(<scope>): <imperative summary>`, lower case, no final period. Epics: `epic: <summary>`.
- Body: the `###` headings for the type, in the order listed in `docs/ISSUES.md`, with nothing before the first heading. Omit optional sections that have no content; never write "N/A".
- Acceptance criteria: `- [ ]` items, each observable in the diff, the running app or a test. Do not repeat the always-applicable criteria (format, analyze, tests, coverage, `MasterContainer`, `AppRoutes`, mock handler).
- Out of scope: concrete exclusions, with issue numbers when the excluded work has its own issue.
- Dependencies: `Part of #N. Blocked by #N. Blocks #N. Related: #N.` Numbers only.
- Labels: one type label, one `size:` label, one `priority:` label when known, plus `good first issue` or `needs: backend` when they apply.

### 4. Style

- No emoji anywhere: title, headings, bullets, labels.
- Plain, short sentences. No marketing language, no "we should", no exclamation marks.
- Bold only for a word that must not be missed (for example **false** in a privacy default). Never bold whole sentences.
- Code identifiers, paths, routes and commands in backticks.

### 5. Confirm, then publish

Show the full draft (title, labels, body) to the user. Create or edit issues on GitHub only after the user approves, then report the issue URLs.

```bash
gh issue create --title "<title>" --label "bug" --label "size: XS" --body-file <draft.md>
gh issue edit <n> --body-file <draft.md>
```

For an epic, create the sub-issues first, then the epic with their numbers in its task list, then add `Part of #<epic>` to each sub-issue.

## Rewriting existing issues

When asked to clean up issues: keep the meaning, the acceptance criteria and every issue link; map old sections to the current headings (`Definition` usually becomes `Today` plus `What to build`); move size, priority and dependency lines into their sections or labels; strip all emoji. Show a before and after for one issue and get approval before editing the rest.

## Reject a draft that

- has a title without a type and scope, or with emoji;
- has a heading not defined for its type, or headings out of order;
- has an acceptance criterion that cannot be checked;
- has no out-of-scope section (except a task where it is optional);
- refers to another issue by description instead of number;
- is size L and could have been split.
