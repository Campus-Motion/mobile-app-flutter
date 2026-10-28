---
name: campus-motion-ui-quality
description: Build and review Campus Motion Flutter screens and widgets that reuse the shared component library, use AppColors tokens, sit inside MasterContainer, cover loading, empty and error states, and stay accessible. Use for any change under mobile_app/lib/screens or mobile_app/lib/widgets, for implementing a Figma screenshot or mockup, for extracting widgets from a large screen, and for UI review.
---

# Campus Motion UI quality

Deliver complete, consistent screens without growing monolithic files or bypassing the design system.

## Required context

Read `AGENTS.md`, `docs/DESIGN.md` (tokens and the widget catalog) and `docs/ARCHITECTURE.md` section 3 (layers). Then read the screen you are changing, every widget in `lib/widgets/` you might reuse, and their tests in `test/widgets/`.

## Workflow

### 1. Establish behaviour

- Write down what the screen shows and does, from the issue's acceptance criteria.
- List the states that can occur: loading, loaded, empty, error, and for actions pending and failed.
- Note any health data or other users' data on the screen; if present, also load `campus-motion-privacy`.

### 2. Reuse before creating

Search `lib/widgets/` and use this order:

1. An existing widget as is (`AppCard`, `AppButton`, `StatItem`, `ActivityCard`, `EventPreviewCard`, `NewsCard`, `SectionHeader`, `TopAppBar`, ...).
2. A composition of existing widgets.
3. A new widget in `lib/widgets/<name>.dart` when an element repeats or carries more than a few lines of layout.

A new widget is a `StatelessWidget` with a `const` constructor and `super.key`, takes its data and callbacks as parameters, uses only `AppColors`, does not call services or push routes, and has a widget test in `test/widgets/<name>_test.dart`. Add it to the catalog in `docs/DESIGN.md`.

### 3. From a screenshot

1. Name every element on the mockup and map it to a widget from step 2.
2. Map every colour to the nearest `AppColors` token; ask before adding a token.
3. Map spacing to 4, 8, 12, 16, 20, 24, 32 and radii to cards 20, buttons 14, chips 8.
4. Build the missing widgets first, with tests, then compose the screen.

### 4. Compose the screen

- Root: `MasterContainer`, with `onRefresh` for data screens and `bottomNavigationBar: CampusMotionBottomBar(...)` for tab screens.
- Data: through a service held by the screen; never `http`. After each `await`, `if (!mounted) return;`.
- Navigation: `Navigator.pushNamed(context, AppRoutes.<name>)`; register new screens in `AppRoutes` and in the route table in `docs/ARCHITECTURE.md`.
- Every state from step 1 is rendered. Buttons that trigger requests use `AppButton(isLoading: ...)`.
- The screen file only composes widgets and binds state. If it passes roughly 300 lines, extract.
- When you edit part of an older screen, migrate the `Colors.*` literals and raw `$e` error messages in that part.

### 5. Accessibility and copy

- Tap targets at least 48 by 48; icon-only buttons have a `tooltip` or `Semantics` label.
- Never rely on colour alone; pair it with an icon or text.
- No overflow at 320 px width, with long names, or with large system fonts.
- Sentence case, short, friendly copy. No emoji. Errors say what happened and what to do, never raw exception text.

### 6. Verify

From `mobile_app/`: the targeted widget tests, then `dart format --output=none --set-exit-if-changed .`, `flutter analyze --fatal-infos`, `flutter test --coverage`, `dart run tool/check_coverage.dart`. Run the screen in mock mode when you can and describe what you checked. Then review the diff with `campus-motion-minimal-change`.

## Reject a change that

- adds `Color(0x...)` or `Colors.*` in a screen or widget;
- adds inline-styled cards or `_buildX()` helpers that duplicate a shared widget;
- adds a screen without `MasterContainer` or without an `AppRoutes` entry;
- calls `http` or parses JSON in a screen or widget;
- leaves a loading, empty or error state unhandled;
- adds a shared widget without a widget test or without a catalog entry;
- uses `context` after an `await` without a `mounted` check;
- adds a package or a state-management library;
- calls a service from `build()` or loads the same data twice;
- restyles or reorganizes parts of the screen the issue does not mention.
