# Design

How Campus Motion looks and why, for anyone adding a screen.

This is a reference for the pieces that exist and the decisions behind them. The rules a UI change has to satisfy are in [`.claude/skills/campus-motion-ui-quality/SKILL.md`](../.claude/skills/campus-motion-ui-quality/SKILL.md), written for agents but binding for everyone. Read that before writing a widget; read this to find what already exists and which token to use. [ARCHITECTURE.md](ARCHITECTURE.md) covers where files go.

## The direction

Warm, light and calm. White surfaces, one terracotta brand colour used for action and emphasis, and greys for everything else. Colour should mean something: the brand colour says "this is interactive or important", status colours say success, warning or error, and activity colours identify a sport.

Hierarchy comes from type size, weight and spacing, not from stacking boxes. A screen is a header, then sections; a section is a title, then cards. If you need a card inside a card, reconsider the layout.

The app is a phone app on every platform. `MasterContainer` keeps every screen in a centred column of at most 450 px.

## Colour tokens

Every colour comes from `AppColors` (`mobile_app/lib/constants/colors.dart`). Writing `Color(0xFF...)` or `Colors.*` in a screen or widget is a bug, even if the value matches a token. If you need a colour that does not exist, add a token there first and explain why in the PR.

| Group | Tokens | Use for |
|---|---|---|
| Brand | `primary` (#DE7356), `primaryLight`, `primaryDark` | Primary buttons, active tab, links, highlighted figures. `primaryLight` for tinted backgrounds, `primaryDark` for pressed states. |
| Surfaces | `background`, `cardBackground`, `surfaceLight`, `divider` | Screen background, cards, subtle panels and input fills, separators. |
| Text | `textPrimary`, `textSecondary`, `textMuted` | Body and titles, supporting text, hints and timestamps. |
| Status | `success`, `warning`, `error`, `info` | Feedback only: confirmations, warnings, errors, neutral notices. Never decoration. |
| Activities | `activityRun`, `activityWalk`, `activityCycle`, `activityHike`, `activitySwim`, `activityDefault` | Sport icons and accents. Map a type to its colour through `ActivityCard.getActivityColor`, not a new switch. |
| Shadow | `shadow` | The one card shadow (8% black). |

Many screens still contain `Colors.*` literals from before the token system. When you touch a screen, migrate the colours in the part you change; do not add new ones.

## Spacing, radius, elevation

- **Spacing scale:** 4, 8, 12, 16, 20, 24, 32. Screen side padding is 24 (the `MasterContainer` default). Space between cards is 16.
- **Radius:** cards 20, buttons 14, chips and small tags 8.
- **Elevation:** one soft shadow (`AppColors.shadow`, blur about 10) on cards and the bottom bar. No stacked or coloured shadows.

## Typography

There is no type scale in code yet; these are the sizes in use. Stick to them.

| Role | Size | Weight |
|---|---|---|
| Screen title | 28 | bold |
| Section header (`SectionHeader`) | 22 | bold |
| Card title | 16 | semibold |
| Body | 14 to 15 | regular |
| Caption, label, timestamp | 12 | regular, `textSecondary` or `textMuted` |

## Shared widgets

Check this list before building anything. Reuse first, compose second, create a new widget in `lib/widgets/` only when nothing fits, and add it to this table in the same PR.

| Widget | File | Use it for |
|---|---|---|
| `MasterContainer` | `master_container.dart` | The root of every screen: 450 px column, safe area, scrolling, pull-to-refresh (`onRefresh`), bottom bar and FAB slots. |
| `CampusMotionBottomBar` | `bottom_bar.dart` | The four main tabs (0 Home, 1 Sport, 2 Social, 3 Profile). |
| `TopAppBar` | `top_bar.dart` | The logo header at the top of tab screens. |
| `SectionHeader` | `section_header.dart` | A bold title that opens a section ("Upcoming Events"). |
| `AppCard` | `app_card.dart` | Any card: 20 radius, shadow, padding, optional `onTap`. |
| `AppButton` | `app_button.dart` | Every button. Variants `primary`, `secondary`, `outline`, `danger`; `isLoading` shows a spinner and blocks taps; optional `icon`. |
| `StatItem` | `stat_item.dart` | A figure with unit and label ("12.4 km, Distance"). |
| `ActivityCard` | `activity_card.dart` | One logged activity: sport icon and colour, title, date, duration, public or private badge. Owns the activity type to icon and colour mapping. |
| `EventPreviewCard` | `event_preview_card.dart` | A square upcoming-event tile for horizontal carousels. |
| `NewsCard` | `news_card.dart` | One news item with optional cover photo, date, title and body. |
| `PrivacyPolicyDialog` | `privacy_policy_dialog.dart` | The privacy policy, opened with `PrivacyPolicyDialog.show(context)`. |
| `ThemedText` | `themed_text.dart` | Text bound to the app text theme. |

Planned shared widgets with open issues: `LoadingState`, `ErrorState`, `EmptyState` (#7).

### Building from a Figma screenshot

1. Name every visual element on the mockup and map it to a widget above.
2. Anything left over that appears more than once, or is more than a few lines of layout, becomes a new widget in `lib/widgets/`.
3. The screen file only composes those widgets inside `MasterContainer` and binds data to them.
4. Map every colour on the mockup to the closest `AppColors` token. If none is close, ask before adding a token.

## States

Every screen that loads data shows four states: loading (spinner in `primary`), loaded, empty (a short sentence saying there is nothing yet, and what to do), and error (a readable message and, where it makes sense, a retry). A button that triggers a request uses `AppButton(isLoading: ...)` so it cannot be tapped twice.

## Copy

- Short, direct and friendly. "Join event", not "Click here to join this event".
- Sentence case for buttons, titles and labels.
- **No emoji** in the interface, in commit messages, in PR descriptions, in issues or in documentation. Use icons from Material `Icons` when a visual cue is needed.
- Error messages say what went wrong and what to do next. Do not show raw exception text, stack traces or server responses to users. (Several screens still show `$e` in snack bars; fix them when you touch them.)
- Use realistic, anonymized names in mock data and tests. No `foo`, `bar` or `test`.

## Accessibility floor

- Tap targets at least 48 by 48.
- Text contrast at least 4.5:1 against its background. `textMuted` is for secondary hints, not essential information.
- Never rely on colour alone: the public or private badge pairs its colour with an icon, and errors pair red with text.
- Icon-only buttons get a `tooltip` or `Semantics` label.
- Layouts must survive long names, large system font sizes and a 320 px wide screen without overflow.
