# Backend API

The REST contract the app consumes, as implemented in `mobile_app/lib/services/`. The backend lives in its own repository (Campus-Motion/Back_End_App) and owns the authoritative contract; this page records what the app expects so mobile work can proceed without reading backend code. When a service changes an endpoint, update this page and `MockDataService` in the same PR.

## Basics

| | |
|---|---|
| Base URL | `https://api.campusmotion.ch` (`ApiService.baseUrl`) |
| Format | JSON request and response bodies, `Content-Type: application/json; charset=UTF-8` |
| Auth | `Authorization: Bearer <access_token>`, token returned by `POST /auth/login` and held in memory by `ApiService` |
| List envelope | List endpoints return `{ "data": [ ... ] }` |
| Debug web | Requests go through `https://corsproxy.io/?<url>` so the browser accepts them |

### Roles

| Role | Can |
|---|---|
| `user` | Manage their own data (default role). |
| `moderator` | Also create events and post news. |
| `admin` | Full access, including user management and moderation. |

### Query parameters on lists

List endpoints accept optional pagination and filter parameters, for example `GET /events?limit=5&after=2026-04-01T00:00:00Z`. The ones the app uses are listed per endpoint below.

## Endpoints

### Auth (`AuthService`)

| Method | Path | Purpose |
|---|---|---|
| POST | `/auth/register` | Create an account (`username`, `email`, `password`). |
| POST | `/auth/login` | Sign in; returns the access token. |
| POST | `/auth/logout` | Invalidate the session. |
| PUT | `/auth/password` | Change password (current and new password). |

### Users and social (`UserService`)

| Method | Path | Purpose |
|---|---|---|
| GET | `/users/me` | Current user. |
| PUT | `/users/me` | Update `username` or `email`. |
| DELETE | `/users/me` | Delete the account and all its data (GDPR Art. 17). |
| POST | `/users/me/photo` | Upload a profile photo (multipart, field `photo`); returns `photo_url`. |
| GET | `/users/me/preferences` | Sport preferences. |
| PUT | `/users/me/preferences` | Update preferences. |
| GET | `/users/{id}` | Another user's public profile. |
| GET | `/users/{id}/followers` | Followers list. |
| GET | `/users/{id}/following` | Following list. |
| POST | `/users/{id}/follow` | Follow a user. |
| DELETE | `/users/{id}/follow` | Unfollow a user. |

### Health (`UserService`)

Special-category data. See [ARCHITECTURE.md](ARCHITECTURE.md#6-privacy-architecture-gdpr) before touching these.

| Method | Path | Purpose |
|---|---|---|
| GET | `/health` | The user's health record, or 404 if none. |
| POST | `/health` | Create it. Requires `consent_given_at`; metrics travel inside `sensitive_data` with `client_key_version`. |
| PUT | `/health` | Update it. |
| DELETE | `/health` | Delete it (consent withdrawn or erasure request). |

### Activities (`ActivityService`)

| Method | Path | Purpose |
|---|---|---|
| GET | `/activities` | List. Query: `limit`, `cursor`, `type`, `public`. |
| GET | `/activities/{id}` | One activity. |
| POST | `/activities` | Log an activity (`is_public` defaults to `false`). |
| PUT | `/activities/{id}` | Update fields. |
| DELETE | `/activities/{id}` | Delete. |

### Events (`EventService`)

| Method | Path | Purpose |
|---|---|---|
| GET | `/events` | List. Query: `limit`, `offset`, `after` (ISO 8601, upcoming only). |
| GET | `/events/{id}` | One event. |
| GET | `/events/{id}/participants` | Participants (list of users). |
| POST | `/events/{id}/participants` | Join. |
| DELETE | `/events/{id}/participants` | Leave. |

### News (`NewsService`)

| Method | Path | Purpose |
|---|---|---|
| GET | `/news` | Latest news items. |

## Models

Each response is parsed into a model in `mobile_app/lib/models/`: `User`, `UserPreferences`, `HealthData`, `Activity`, `Event`, `NewsItem`. JSON keys are `snake_case`; Dart fields are `camelCase`; the mapping lives in each model's `fromJson` and `toJson`. A new field must be optional or defaulted in `fromJson` so older payloads still parse.

## Adding or changing an endpoint

1. Agree on the shape with the backend owner (link the backend issue in your PR).
2. Add or change the method in the right service; parse into a model; throw a readable `Exception` on a non-success status.
3. Add the handler to `MockDataService` with realistic data.
4. Add a test that runs the service in mock mode.
5. Update the tables on this page.
