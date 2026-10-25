# Contributing

How a change goes from an idea to `main`: issues, branches, commits, pull requests, checks and reviews.

## Related documents

- Entry point and documentation hub: [README.md](README.md)
- Local setup: [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md)
- Where code goes: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- How screens look: [docs/DESIGN.md](docs/DESIGN.md)
- Writing issues: [docs/ISSUES.md](docs/ISSUES.md)
- Working with an AI agent: [docs/STUDENT_WORKFLOW_GUIDE.md](docs/STUDENT_WORKFLOW_GUIDE.md)
- Agent contract: [AGENTS.md](AGENTS.md)

## Who can contribute

Development has so far been done by students who took a software-engineering course at EPFL (such as SwEnt), but the project is open to any student with solid programming knowledge and the wish to build something useful for the campus. The practices below are what keep a project with many contributors from falling apart.

## Principles

1. **Think before you build.** Every change starts from an issue. If you have an idea, open an issue (see [docs/ISSUES.md](docs/ISSUES.md)) and discuss it with the team before writing code. Random additions do not move the project forward.
2. **Work on a branch, never on `main`.** A branch isolates your work so people do not overwrite each other, and shows the team who is working on what. **Never push to `main` directly.**
3. **Commit small and often.** If you could tell a teammate "by the way, I did X", that is a commit. Push after each meaningful step.
4. **Describe your pull request.** Someone else will build on your code. State what you did, why, what it changes and how to test it.
5. **Test what you build.** Tests catch the bug you did not think of, and the one someone else introduces next month.
6. **Respect the structure.** Where a file lives matters as much as what it contains. Look for an existing widget or service before writing a new one. Writing the same thing twice is a bug waiting to happen.
7. **Change as little as possible.** The best pull request is the smallest one that solves its issue, built from code that already exists. See [Minimal changes and reuse](#minimal-changes-and-reuse).
8. **Never commit secrets.** API keys, tokens and passwords stay in a local, git-ignored file. If you work with keys or health data and are unsure how to handle them, ask before doing anything.
9. **Credit others.** Do not copy someone else's work without attribution.

## Minimal changes and reuse

Good code is efficient code, and good programmers reuse what has already been written. Every pull request is held to these rules, and reviewers send back pull requests that break them. The full rule set is in [AGENTS.md](AGENTS.md#minimal-reuse-first-changes); in short:

- **Search before you write.** Before adding a widget, method, helper or constant, search the code for one that already does the job: `grep -rn "<word>" lib test` from `mobile_app/`, the widget catalog in [docs/DESIGN.md](docs/DESIGN.md#shared-widgets), and the services in [docs/API.md](docs/API.md).
- **Reuse, then extend, then create.** Use existing code as it is. If it almost fits, add an optional parameter to it. Write something new only when neither works.
- **Never copy and adjust.** If you need logic that exists elsewhere, call it, or move it into a shared function that both places call.
- **Touch only what the issue needs.** No renames, reformatting of untouched code, or unrelated fixes. Open a separate issue for anything else you notice.
- **No dead code.** No unused parameters or imports, no commented-out code, no "might be useful later".
- **Be efficient.** Fetch data once per screen, never in `build()`; ask the API for only what you show (`limit`, `after`); run independent requests with `Future.wait`; use `ListView.builder` for lists; use `const`; dispose controllers.
- **Keep it reviewable.** Aim for at most about 400 changed lines outside tests. Bigger work becomes several issues.

The pull request template asks you to list what you reused and to justify every new widget, method, file or package.

## Workflow

### 1. Take an issue

Pick an open issue, assign yourself or comment that you are taking it, and read its acceptance criteria and out-of-scope sections. Ask in the issue if anything is unclear.

### 2. Branch

```bash
git switch main
git pull
git switch -c issue-<number>/<short-slug>      # e.g. issue-4/pull-to-refresh-past-events
```

Without an issue (rare, small fixes only): `<type>/<short-slug>`, where type is `feat`, `fix`, `refactor`, `chore`, `docs` or `test`.

### 3. Commit

Commits follow [Conventional Commits](https://www.conventionalcommits.org/): `<type>(<scope>): <imperative summary>`, lower case, no final period, no emoji.

```
feat(events): add join button and participant counter
fix(auth): check mounted before navigating after login
test(widgets): cover NewsCard without a photo
```

Use the same types and scopes as issue titles ([docs/ISSUES.md](docs/ISSUES.md#title)).

### 4. Open a pull request

Open the PR against `main` once the checks pass locally. The title follows the commit format. GitHub fills the description from `.github/pull_request_template.md`; complete every section:

- **What and why:** the change and the reason, with `Closes #<issue>`.
- **Reused:** the existing widgets, services and helpers the change builds on.
- **New code and why:** every new widget, method, file or package, and why nothing existing fitted.
- **Layers touched:** screens, widgets, services, models, routes.
- **How it was tested:** automated tests added, plus manual steps (mock or real backend, platform).
- **Screenshots** for any visual change.
- **Limitations or follow-ups**, with issue numbers.

Keep PRs small: one issue, one PR. A PR that touches many unrelated files will be sent back.

### 5. Checks and review

Every PR runs CI (`.github/workflows/ci.yml`). It must be green before review. Then at least one teammate reviews. Address every comment, either with a change or a reply explaining why not.

If you use an AI agent: `/fix-ci` repairs a red CI from the failed logs, and `/correct-pr` applies review comments. Both are defined in [AGENTS.md](AGENTS.md#9-automated-workflows).

### 6. Merge

A human merges once CI is green and the review is approved. Delete the branch after the merge. If a merge breaks `main`, fix it on a new branch through a normal PR, never by pushing to `main`.

## Quality gates

Run these from `mobile_app/` before pushing. CI runs exactly the same steps.

```bash
dart format --output=none --set-exit-if-changed .   # formatting (fix with: dart format .)
flutter analyze --fatal-infos                        # zero errors, warnings and infos
flutter test --coverage                              # all tests
dart run tool/check_coverage.dart                    # line coverage floor
```

Never make a check pass by weakening it: no `// ignore:`, no relaxed `analysis_options.yaml`, no deleted or loosened assertions, no lowered coverage floor. Fix the code.

## Testing

| Change | Expected test |
|---|---|
| New or changed shared widget | Widget test in `test/widgets/<widget>_test.dart` |
| New or changed service method | Test running the service in mock mode (`ApiService.mockMode = true`) |
| New or changed model field | `fromJson` / `toJson` test, including an old payload without the field |
| Bug fix | A regression test that fails without the fix, or a note in the PR explaining why one is impossible |
| Screen change | Widget test where practical; manual test steps in the PR otherwise |

Test files must end in `_test.dart`.

## Documentation

Update the docs in the same PR when you change what they describe:

| You changed | Update |
|---|---|
| A route | Route table in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md#routing) |
| A shared widget (added, removed, renamed) | Widget catalog in [docs/DESIGN.md](docs/DESIGN.md#shared-widgets) |
| A colour token | Token table in [docs/DESIGN.md](docs/DESIGN.md#colour-tokens) |
| An endpoint or model | [docs/API.md](docs/API.md) and `MockDataService` |
| Setup, commands or CI | [docs/GETTING_STARTED.md](docs/GETTING_STARTED.md), this file, [AGENTS.md](AGENTS.md) |
| A user-visible feature | Status table in [docs/FUNCTIONAL_OVERVIEW.md](docs/FUNCTIONAL_OVERVIEW.md#6-current-status) |
| A project rule | [AGENTS.md](AGENTS.md), and the matching skill in both `.claude/skills/` and `.agents/skills/` |

## PR checklist

- [ ] Linked to an issue (`Closes #N`), scope limited to that issue
- [ ] Every changed line is needed by the issue; no unrelated edits or dead code
- [ ] Existing widgets, services and helpers reused; no duplicated logic
- [ ] No service calls in `build()`, no duplicate fetches
- [ ] Format, analyze, tests and coverage pass locally
- [ ] New behaviour is covered by tests
- [ ] Screens in `MasterContainer`, routes in `AppRoutes`, colours from `AppColors`
- [ ] New endpoints have a `MockDataService` handler
- [ ] Health data only with consent; new activities private by default
- [ ] Docs updated where needed
- [ ] No secrets, no debug `print`, no emoji
