## What and why

<!-- The change and the reason. Keep the line below so the issue closes on merge. -->

Closes #

## Reused

<!-- Existing widgets, services, helpers and mock handlers this change builds on. -->

## New code and why

<!-- Every new widget, method, file or package, and why nothing existing fitted. Write "None" if there is none. -->

## Layers touched

<!-- Screens, widgets, services, models, routes. -->

## How it was tested

<!-- Automated tests added or updated, and manual steps (platform, mock or real backend). -->

## Screenshots

<!-- Required for any visual change. Delete this section otherwise. -->

## Limitations and follow-ups

<!-- Known gaps, with issue numbers. Delete this section if there are none. -->

## Checklist

- [ ] Every changed line is needed by the issue; no unrelated edits, renames or reformatting
- [ ] Existing code reused or extended; no copied-and-adjusted logic, no dead or commented-out code
- [ ] No service calls in `build()`, no duplicate fetches, lists use `ListView.builder`
- [ ] Fewer than about 400 changed lines outside tests, or the reason it cannot be split is explained above
- [ ] Format, analyze, tests and coverage pass locally
- [ ] Screens in `MasterContainer`, routes in `AppRoutes`, colours from `AppColors`
- [ ] New endpoints have a `MockDataService` handler
- [ ] Health data only with consent; new content private by default
- [ ] Docs updated where needed; no secrets, no `print`, no emoji
