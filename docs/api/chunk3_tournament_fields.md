# API Spec: Tournament Object Optional Schema Fields

This document specifies the additional optional fields added to the `Tournament` object returned by both `GET /v1/tournaments` and `GET /v1/tournaments/{tid}` endpoints.

---

## 1. Endpoints Overview

- **Endpoints**:
  - `GET /v1/tournaments` (List tournaments)
  - `GET /v1/tournaments/{tid}` (Get single tournament detail)
- **Authentication**: Optional / Bearer Token (`Authorization: Bearer <token>`)
  - Guest requests (no token or invalid token): `is_registered` must be `null` or omitted.
  - Authenticated requests: `is_registered` must be computed dynamically for the requesting user.

---

## 2. New Schema Fields

| Field Name | JSON Key | Type | Nullable | Description |
| :--- | :--- | :--- | :--- | :--- |
| Start Timestamp | `starts_at` | `string` | Yes | Start time of tournament in ISO 8601 UTC format (e.g., `2026-10-10T15:30:00Z`). |
| Capacity Slots | `max_slots` | `integer` | Yes | Maximum allowed registration slots for teams/players (e.g., `48`). |
| Filled Slots | `filled_slots` | `integer` | Yes | **Live count** of currently registered teams/players (e.g., `32`). |
| User Registration | `is_registered` | `boolean` | Yes | `true` if the requesting user/team is registered; `false` if not; `null`/absent if unauthenticated guest. |

---

## 3. Example Request & Responses

### Example 1: Authenticated User Request (`GET /v1/tournaments/tn_ff_2026_001`)

#### Request Headers
```http
GET /v1/tournaments/tn_ff_2026_001 HTTP/1.1
Host: blastx-esports-backend-production-4b5f.up.railway.app
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Accept: application/json
```

#### Success Response (200 OK)
```json
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
  "starts_at": "2026-10-10T15:30:00Z",
  "organizer": "Garena",
  "organizerVerified": true,
  "max_slots": 48,
  "filled_slots": 32,
  "slots_left": 16,
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
  ]
}
```

---

### Example 2: Guest / Unauthenticated Request (`GET /v1/tournaments`)

#### Request Headers
```http
GET /v1/tournaments?game=Free+Fire&status=upcoming HTTP/1.1
Host: blastx-esports-backend-production-4b5f.up.railway.app
Accept: application/json
```

#### Success Response (200 OK)
```json
{
  "data": [
    {
      "id": "tn_ff_2026_002",
      "title": "Free Fire Weekly Cup #14",
      "game": "Free Fire",
      "banner_url": "https://cdn.blastx.gg/banners/weekly_14.png",
      "prize_pool": 25000,
      "currency": "₹",
      "status": "UPCOMING",
      "starts_at": "2026-10-12T18:00:00Z",
      "organizer": "BlastX Esports",
      "max_slots": 48,
      "filled_slots": 48,
      "is_registered": null,
      "team_mode": "SQUAD",
      "map": "BERMUDA",
      "entry_fee": 0
    }
  ],
  "total": 1
}
```

---

## 4. Error Responses

### 400 Bad Request
```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "Invalid tournament ID or query parameter"
}
```

### 401 Unauthorized
Returned if an expired or malformed Bearer Token is supplied in the `Authorization` header.
```json
{
  "statusCode": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired access token"
}
```

### 404 Not Found
```json
{
  "statusCode": 404,
  "error": "Not Found",
  "message": "Tournament not found"
}
```

### 500 Internal Server Error
```json
{
  "statusCode": 500,
  "error": "Internal Server Error",
  "message": "Failed to calculate live slots count or retrieve tournament data"
}
```

---

## 5. Implementation Notes for Backend Developers

1. **`is_registered` Calculation**:
   - Must be computed per request using the user ID extracted from the Bearer JWT token in the `Authorization` header.
   - Return `true` if the user (or the user's team) is registered for the specified tournament ID.
   - Return `null` (or omit key) when no valid `Authorization` header is present (guest mode).

2. **`filled_slots` Live Counting**:
   - `filled_slots` must be a real-time live count of all confirmed player/team registrations for the tournament.
   - When a user registers or unregisters, `filled_slots` must update atomically.

3. **Client Fallback & Legacy Schema**:
   - Mobile client handles missing or `null` fields gracefully using client-side mock fallbacks (`// TODO(backend): remove mock`), preserving full backward compatibility.
