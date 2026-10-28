# Functional overview

This document describes **what Campus Motion is for**, **who uses it** and **the principles behind it**, without implementation detail. For the technical view read [ARCHITECTURE.md](ARCHITECTURE.md); for the interface read [DESIGN.md](DESIGN.md).

## 1. What Campus Motion is

Campus Motion is a sports and health community app for the EPFL and UNIL campuses. It makes the sport happening on campus visible and easy to join: a connected running trail around campus, weekly events organized by students and clubs, personal activity tracking, and a social layer to find training partners.

The goal is a campus that moves together. Students should meet through sport, push each other, and stay healthy physically and mentally, in an environment that treats their health data with respect.

## 2. The problem it solves

- **Sport on campus is scattered.** Events live in club group chats, mailing lists and posters. A student who wants to join a run has no single place to look.
- **Training alone is hard to sustain.** Finding people at your level, nearby, with the same sport is mostly luck.
- **Health apps take more than they give.** Mainstream fitness apps send body metrics and location to third-party clouds and analytics. Students have little visibility or control.

## 3. Who uses it

| User | What they do |
|---|---|
| Student or staff member | Browses events and news, joins events, logs activities, follows other members, manages their own profile and data. |
| Moderator | Everything a member does, plus creating events and posting news. |
| Admin | Everything a moderator does, plus user management and moderation. |

Roles are enforced by the backend. The app currently exposes the member experience; moderator and admin tools are planned (see the open admin portal epic on GitHub).

## 4. Navigation: four tabs

After sign-in, the bottom bar gives access to four tabs. Each tab is one top-level screen.

| Tab | What it shows |
|---|---|
| **Home** | Upcoming events (horizontal carousel) and the latest campus sport news. |
| **Sport** | Three sub-tabs: **Activities** (your logged activities, with a button to log a new one), **Events** (events you joined and events to discover, with join and leave), and **Connected Trail** (trail stats; trail tracking is coming soon). |
| **Social** | Three sub-tabs: **Following**, **Followers** and **Find User**, to follow or unfollow other members. |
| **Profile** | Your profile and activity summary, with access to profile editing and settings. |

Before sign-in, a welcome screen offers sign-in, sign-up and an offline demo mode.

## 5. The privacy promise

Health and body data are treated as the most sensitive data the app handles. The promise to users is:

- **Nothing sensitive without consent.** Weight, height and date of birth are only stored after the user explicitly opts in, and the consent can be withdrawn at any time from settings.
- **Private by default.** A newly logged activity is visible only to its owner until they choose to make it public.
- **Your data, under your control.** From settings, users can export all their data as a JSON file, delete their health data, or delete their account entirely.
- **Limited retention.** Health records carry an expiry date (two years by default) after which they are purged.
- **No third-party cloud.** The app talks only to Campus Motion's own backend. No analytics SDK, no Firebase, no tracking.
- **Transparency.** A privacy policy is shown in the app, and users should always be able to see what is stored about them and why.

Any feature that touches health data, location, or what other users can see must keep these promises. [ARCHITECTURE.md](ARCHITECTURE.md#6-privacy-architecture-gdpr) describes how the code enforces them.

## 6. Current status

| Area | Status |
|---|---|
| Sign-in, sign-up, demo mode | Working |
| Home: events carousel and news | Working |
| Sport: activities (log, list, delete) | Working |
| Sport: events (discover, join, leave) | Working |
| Sport: connected trail | Placeholder ("coming soon") |
| Social: follow, unfollow, search | Working |
| Profile, edit profile, settings, data export, deletion | Working |
| Event details screen | In progress |
| Events feed from partner clubs (Strava) | Planned (epic) |
| Club directory and following clubs | Planned (epic) |
| In-app admin portal | Planned (epic) |

The GitHub issues and epics are the source of truth for planned work: <https://github.com/Campus-Motion/mobile-app-v2/issues>.
