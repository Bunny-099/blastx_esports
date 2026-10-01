# API Spec: Tournament List Search & Status Filters

This document defines the requirements and schema updates for search and status filtering on the `GET /v1/tournaments` endpoint.

---

## 1. Endpoint Overview

- **Endpoint**: `/v1/tournaments`
- **Method**: `GET`
- **Authentication**: Optional / Bearer Token (`Authorization: Bearer <token>`)

---

## 2. Request Parameters

### Query Parameters

| Parameter | Type | Required | Default | Description |
| :--- | :--- | :--- | :--- | :--- |
| `game` | `string` | No | - | Filter by game name (e.g. `Free Fire`). |
| `status` | `string` | No | `live` | Filter by tournament status. Allowed values: `live`, `upcoming`, `completed`, `all`. |
| `q` | `string` | No | - | Case-insensitive search query matching title (`name`/`title`), organizer (`organizer`), or map name (`map`). |
| `cursor` | `string` | No | - | Opaque pagination cursor string for cursor-based pagination. |
| `limit` | `integer` | No | `20` | Max items to return per page (1 to 50). |
| `page` | `integer` | No | `1` | Fallback page number if using offset-based pagination. |

### Example Request URL
```
GET /v1/tournaments?game=Free+Fire&status=live&q=bermuda&limit=20
```

---

## 3. Response Specification

### Response Headers
- `Content-Type: application/json`

### Success Response (200 OK)

> [!NOTE]
> The Flutter app supports both the new `{ "data": [...], "next_cursor": ... }` response structure and the legacy `{ "items": [...] }` or raw array list structure.

```json
{
  "data": [
    {
      "id": "tn_ff_2026_001",
      "title": "Free Fire World Series Qualifiers",
      "game": "Free Fire",
      "banner_url": "https://cdn.blastx.gg/banners/ffws_2026.png",
      "gameLogoUrl": "https://cdn.blastx.gg/logos/ff_icon.png",
      "prize_pool": 100000,
      "currency": "₹",
      "viewersCount": 12500,
      "status": "LIVE",
      "starts_at": "2026-10-01T18:00:00Z",
      "organizer": "Garena",
      "organizerVerified": true,
      "max_slots": 48,
      "registered_count": 48,
      "slots_left": 0,
      "team_mode": "SQUAD",
      "map": "BERMUDA",
      "format": "BATTLE_ROYALE",
      "entry_fee": 0,
      "perKillReward": 500,
      "booyahBonus": 2000,
      "is_registered": true,
      "prize_distribution": [
        { "label": "1st Place", "amount": 50000 },
        { "label": "2nd Place", "amount": 30000 },
        { "label": "3rd Place", "amount": 20000 }
      ],
      "rules": ["Standard FFWS rules apply", "No emulators permitted"],
      "announcements": ["Round 2 starts at 7:30 PM IST"]
    }
  ],
  "next_cursor": "eyJpZCI6InRuX2ZmXzIwMjZfMDAxIiwidGltZSI6MTc1OTI2MjQwMH0=",
  "total": 1
}
```

---

## 4. Error Responses

### 400 Bad Request
Returned when an invalid `status` or limit parameter is supplied.
```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Invalid status parameter. Allowed values: live, upcoming, completed, all"
}
```

### 401 Unauthorized
Returned if an invalid bearer token is provided when requesting user-specific fields (e.g. `is_registered`).
```json
{
  "statusCode": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired access token"
}
```

### 500 Internal Server Error
```json
{
  "statusCode": 500,
  "error": "Internal Server Error",
  "message": "An unexpected error occurred while fetching tournaments"
}
```

---

## 5. Notes for Backend Developers

1. **Case-Insensitive Search (`q`)**:
   - `q` search should use `ILIKE` / case-insensitive regex on `title`, `organizer`, and `map`.
   - Partial matches should be returned (e.g. `q=berm` matches `BERMUDA`).

2. **Status Parameter (`status`)**:
   - `live`: `status = 'LIVE'`
   - `upcoming`: `status = 'UPCOMING'`
   - `completed`: `status = 'COMPLETED'`
   - `all`: returns tournaments across all statuses.

3. **Client-Side Fallback Behavior**:
   - The Flutter mobile client currently performs client-side filtering on the fetched list as a fallback (`// TODO(backend): remove mock`).
   - Returning data adhering to the query params directly improves bandwidth efficiency and app performance without breaking older app builds.
