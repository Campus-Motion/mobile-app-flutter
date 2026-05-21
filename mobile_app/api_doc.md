<USER_REQUEST>
Here is the markdown : # Campus Motion — REST API Documentation

**Base URL:** `https://<your-server>/api/v1/CampusMotion`  
**Format:** All requests and responses use `application/json`  
**Auth:** Protected routes require a Bearer JWT in the `Authorization` header

---

## Authentication

### Roles

| Role        | Description                                          |
| ----------- | ---------------------------------------------------- |
| `user`      | Default role, can manage own data                    |
| `moderator` | Can create events and post news                      |
| `admin`     | Full access including user management and moderation |

### JWT Usage

Include the token returned from `/auth/login` in every protected request:

```
Authorization: Bearer <access_token>
```

---

## Query Parameters

All list endpoints support the following optional query parameters for pagination and filtering.  
Example: `GET /events?limit=5&after=2026-04-01T00:00:00Z`

<truncated 26184 bytes>