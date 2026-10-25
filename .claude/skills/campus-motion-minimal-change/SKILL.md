---
name: campus-motion-minimal-change
description: Review a Campus Motion diff, before hand-off or on a pull request, so that it is the smallest change that solves its issue, reuses existing widgets, services, helpers and mock handlers instead of duplicating them, and avoids wasteful data loading or rebuilds. Use before every hand-off, when asked to review or simplify a change or a PR, and when addressing review comments about size, duplication or efficiency.
---

# Campus Motion minimal change

Cut a diff down to what its issue needs, built from code that already exists.

## Required context

Read `AGENTS.md`, section "Minimal, reuse-first changes". Read the issue (acceptance criteria and out of scope) and the full diff: `git diff origin/main...HEAD` plus uncommitted changes, or `gh pr diff <n>` for a pull request.

## Workflow

### 1. Map every hunk to the issue

For each changed file and hunk, name the acceptance criterion it serves. A hunk that serves none is removed, or moved to a follow-up issue named in the hand-off. Typical offenders: renames, reordered imports or members, reformatting of untouched code, comment edits, unrelated fixes, debug output.

### 2. Hunt for duplication

For every new widget, method, function, constant, extension, model field, mock handler and test helper:

1. Search for an existing equivalent: `grep -rn "<key word>" lib test`, and check the widget catalog in `docs/DESIGN.md` and the endpoint tables in `docs/API.md`.
2. If one exists, use it.
3. If one almost fits, prefer an optional parameter or variant on it over a near-copy, as long as it keeps a single responsibility.
4. If the diff copies a block from elsewhere and adjusts it, replace both copies with one shared function.

Also check the reverse: logic the diff adds inline in a screen that belongs in an existing service, model or widget.

### 3. Remove speculative code

Delete unused parameters, methods, classes, imports and variables; commented-out code; flags, configuration or abstractions with a single use; interfaces with one implementation; new packages that a few lines or an existing dependency cover.

### 4. Check efficiency

| Look for | Replace with |
|---|---|
| A service call inside `build()` | A future started in `initState` and reused |
| The same data fetched twice on one screen, or refetched by a child | One fetch, passed down |
| Loading a full list, then filtering or truncating on the device | API parameters (`limit`, `after`, `type`, `public`) |
| Independent requests awaited one after another | `Future.wait` |
| `ListView(children: ...)` or a `Column` over a list that can grow | `ListView.builder` |
| Missing `const` on constructors with constant arguments | `const` |
| `TextEditingController`, `ScrollController`, `TabController` or subscriptions never disposed | Dispose in `dispose()` |
| `setState` rebuilding a whole screen for one small widget | A smaller stateful widget |

### 5. Check size

If the diff changes more than about 400 lines outside `test/`, propose how to split it into separate issues, unless the PR description already justifies why it cannot be split.

### 6. Report

List each finding as one line: file and line, the problem, the fix. When reviewing your own work, apply the fixes, re-run the checks from `AGENTS.md` section 12, and state in the hand-off what was reused and why each new piece of code was needed.

## Reject a diff that

- contains a hunk no acceptance criterion needs;
- copies and adjusts existing logic instead of calling or extracting it;
- adds a widget, method or helper equivalent to an existing one;
- adds unused or commented-out code, or a single-use abstraction;
- adds a package without the user's approval;
- fetches data in `build()`, fetches the same data twice, or filters on the device what the API can filter;
- exceeds about 400 non-test lines without a justification for not splitting.
