# API Specification: Chunk 6 - Tournament Matches

## Endpoint
`GET /v1/tournaments/{tid}/matches`

## Overview
Retrieves the list of scheduled, live, and completed matches for a given tournament ID, organized across rounds/stages.

---

## Request

### HTTP Method
`GET`

### Headers
| Header | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `Authorization` | String | Optional | Bearer token (`Bearer <jwt_token>`) |
| `Accept` | String | Required | `application/json` |

### Path Parameters
| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `tid` | String | Yes | Unique ID of the tournament (e.g. `tourn_ff_2049`) |

### Query Parameters
None required.

### Request Body
None.

---

## Response

### HTTP 200 OK

```json
{
  "tournament_id": "tourn_ff_2049",
  "matches": [
    {
      "id": "match_101",
      "round": "Round 1 - Qualifiers",
      "match_number": 1,
      "map": "Bermuda",
      "status": "completed",
      "starts_at": "2026-10-02T10:00:00Z",
      "ended_at": "2026-10-02T10:40:00Z",
      "winner_team_name": "Total Gaming",
      "top_killer_name": "FOAB (12 Kills)",
      "stream_url": null
    },
    {
      "id": "match_102",
      "round": "Round 1 - Qualifiers",
      "match_number": 2,
      "map": "Purgatory",
      "status": "completed",
      "starts_at": "2026-10-02T11:00:00Z",
      "ended_at": "2026-10-02T11:40:00Z",
      "winner_team_name": "Team GodLike",
      "top_killer_name": "JONATHAN (9 Kills)",
      "stream_url": null
    },
    {
      "id": "match_103",
      "round": "Round 1 - Qualifiers",
      "match_number": 3,
      "map": "Kalahari",
      "status": "live",
      "starts_at": "2026-10-02T12:00:00Z",
      "ended_at": null,
      "winner_team_name": null,
      "top_killer_name": null,
      "stream_url": "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
    },
    {
      "id": "match_104",
      "round": "Round 1 - Qualifiers",
      "match_number": 4,
      "map": "Alpine",
      "status": "upcoming",
      "starts_at": "2026-10-02T13:00:00Z",
      "ended_at": null,
      "winner_team_name": null,
      "top_killer_name": null,
      "stream_url": null
    },
    {
      "id": "match_201",
      "round": "Round 2 - Semi Finals",
      "match_number": 5,
      "map": "Bermuda",
      "status": "upcoming",
      "starts_at": "2026-10-02T15:00:00Z",
      "ended_at": null,
      "winner_team_name": null,
      "top_killer_name": null,
      "stream_url": null
    }
  ]
}
```

---

## Error Responses

### HTTP 401 Unauthorized
```json
{
  "statusCode": 401,
  "error": "Unauthorized",
  "message": "Invalid or expired authorization token."
}
```

### HTTP 404 Not Found
```json
{
  "statusCode": 404,
  "error": "Not Found",
  "message": "Tournament with ID 'tourn_invalid' was not found."
}
```

### HTTP 500 Internal Server Error
```json
{
  "statusCode": 500,
  "error": "Internal Server Error",
  "message": "An error occurred while fetching tournament matches."
}
```

---

## Backend Developer Notes
1. **Sorting**: Matches should be ordered chronologically by `starts_at` ascending or by `match_number` ascending so round stages present naturally.
2. **Status Field**:
   - `upcoming`: Match is scheduled for the future.
   - `live`: Match is currently in progress.
   - `completed`: Match is finished.
3. **Optional / Nullable Fields**:
   - `ended_at`, `winner_team_name`, `top_killer_name`: Populate when `status` is `completed`.
   - `stream_url`: Live YouTube/Twitch stream or VOD replay link. Can be `null` if no stream is configured.
4. **Polling Optimization**: The client automatically polls this endpoint every 30 seconds when any match in the payload returns `status = "live"`.
