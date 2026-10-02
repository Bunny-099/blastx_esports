# Room Details API Specification

This document details the backend API contract for fetching Free Fire tournament custom room credentials (Room ID and Password).

## Endpoint

- **URL:** `/v1/tournaments/{tid}/room`
- **Method:** `GET`
- **Auth:** `Bearer Token` (Required)

## Request Headers

| Header | Type | Required | Description |
| --- | --- | --- | --- |
| `Authorization` | `String` | Yes | Bearer user access token (`Bearer <token>`) |
| `Accept` | `String` | Yes | `application/json` |

## Path Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| `tid` | `String` | Unique ID of the target tournament |

## Responses

### 1. 200 OK — Room Details Available

Returned when the user (or their team) is registered for the tournament and room credentials are ready to be revealed.

```json
{
  "status": "success",
  "data": {
    "room_id": "8492041",
    "password": "FF2026",
    "visible_from": "2026-10-02T14:45:00Z"
  }
}
```

### 2. 403 Forbidden — User Not Registered

Returned when the authenticated user or their team is not registered in the specified tournament.

```json
{
  "status": "error",
  "code": "NOT_REGISTERED",
  "message": "You must be registered in this tournament to view room details."
}
```

### 3. 409 Conflict / 425 Too Early — Room Details Not Available Yet

Returned when the user is registered, but the room credentials have not been released by the organizer yet (e.g., prior to `visible_from`).

```json
{
  "status": "error",
  "code": "ROOM_NOT_AVAILABLE",
  "message": "Room details are locked until 15 minutes before match start.",
  "reveal_at": "2026-10-02T14:45:00Z"
}
```

### 4. 401 Unauthorized — Missing / Invalid Auth Token

```json
{
  "status": "error",
  "code": "UNAUTHORIZED",
  "message": "Invalid or expired access token."
}
```

## Backend Security & Operational Notes

1. **Authentication & Authorization:** The endpoint **MUST** require a valid user JWT token in the `Authorization` header. It **MUST** verify that the user or their registered team is currently enrolled in the specified tournament (`tid`).
2. **Release Window Guard:** Room credentials **MUST NOT** be exposed before `visible_from` (recommended release window: 10–15 minutes prior to tournament start time).
3. **Public Endpoint Exclusion:** Room ID and Password **MUST NEVER** be returned in public endpoints such as `GET /v1/tournaments` or `GET /v1/tournaments/{tid}`.
4. **Rate Limiting:** Implement strict rate-limiting per user/IP on this endpoint to prevent brute-force attacks or constant polling.
5. **Audit Logging:** Log all successful room credential fetch events on the backend for security tracking.
