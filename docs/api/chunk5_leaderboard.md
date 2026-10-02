# API Specification: Tournament Leaderboard

Endpoint for fetching real-time tournament standings and team rankings.

---

## Endpoint Details

- **Endpoint**: `/v1/tournaments/{tid}/leaderboard`
- **Method**: `GET`
- **Authentication**: Optional / Public (`Bearer <token>` if authenticated)

---

## Query Parameters

| Parameter | Type   | Required | Description |
|-----------|--------|----------|-------------|
| `round`   | String | No       | Filter leaderboard by specific round (e.g. `Grand Final`, `Semi Final`, `Round 1`). If omitted, returns current aggregate standings. |

---

## Request Example

```http
GET /v1/tournaments/ff-matser-2026/leaderboard?round=Grand%20Final HTTP/1.1
Host: blastx-esports-backend-production-4b5f.up.railway.app
Authorization: Bearer <jwt_token>
Accept: application/json
```

---

## Response Example (200 OK)

```json
{
  "tournament_id": "ff-matser-2026",
  "updated_at": "2026-10-02T12:54:19.000Z",
  "round": "Grand Final",
  "entries": [
    {
      "rank": 1,
      "prev_rank": 2,
      "team_id": "team_01",
      "team_name": "Total Gaming",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=TotalGaming",
      "kills": 42,
      "placement_points": 60,
      "total_points": 102,
      "status": "active"
    },
    {
      "rank": 2,
      "prev_rank": 1,
      "team_id": "team_02",
      "team_name": "Team GodLike",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=GodLike",
      "kills": 38,
      "placement_points": 50,
      "total_points": 88,
      "status": "active"
    },
    {
      "rank": 3,
      "prev_rank": 3,
      "team_id": "team_03",
      "team_name": "Orangutan Esports",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=Orangutan",
      "kills": 35,
      "placement_points": 45,
      "total_points": 80,
      "status": "active"
    },
    {
      "rank": 4,
      "prev_rank": 6,
      "team_id": "team_04",
      "team_name": "Team Elite",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=TeamElite",
      "kills": 28,
      "placement_points": 38,
      "total_points": 66,
      "status": "qualified"
    },
    {
      "rank": 5,
      "prev_rank": 4,
      "team_id": "team_05",
      "team_name": "Blind Esports",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=BlindEsports",
      "kills": 25,
      "placement_points": 35,
      "total_points": 60,
      "status": "active"
    },
    {
      "rank": 6,
      "prev_rank": 5,
      "team_id": "team_06",
      "team_name": "Nigma Galaxy",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=NigmaGalaxy",
      "kills": 22,
      "placement_points": 30,
      "total_points": 52,
      "status": "active"
    },
    {
      "rank": 7,
      "prev_rank": 8,
      "team_id": "team_07",
      "team_name": "TSM India",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=TSMIndia",
      "kills": 20,
      "placement_points": 25,
      "total_points": 45,
      "status": "active"
    },
    {
      "rank": 8,
      "prev_rank": 7,
      "team_id": "team_08",
      "team_name": "Chemugu Esports",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=Chemugu",
      "kills": 18,
      "placement_points": 20,
      "total_points": 38,
      "status": "active"
    },
    {
      "rank": 9,
      "prev_rank": 9,
      "team_id": "team_09",
      "team_name": "Team Insane",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=TeamInsane",
      "kills": 15,
      "placement_points": 15,
      "total_points": 30,
      "status": "eliminated"
    },
    {
      "rank": 10,
      "prev_rank": 10,
      "team_id": "team_10",
      "team_name": "Entity Gaming",
      "logo_url": "https://api.dicebear.com/7.x/identicon/svg?seed=EntityGaming",
      "kills": 12,
      "placement_points": 10,
      "total_points": 22,
      "status": "eliminated"
    }
  ]
}
```

---

## Error Codes & JSON Responses

### 404 Not Found
Tournament ID does not exist.

```json
{
  "code": "TOURNAMENT_NOT_FOUND",
  "message": "Tournament with ID ff-matser-2026 was not found"
}
```

### 500 Internal Server Error
Server error fetching leaderboard data.

```json
{
  "code": "INTERNAL_SERVER_ERROR",
  "message": "An unexpected error occurred while calculating standings"
}
```

---

## Backend Developer Notes

1. **`prev_rank` Calculation**:
   - `prev_rank` must represent the team's `rank` at the previous standings update (e.g., after the previous match in the tournament).
   - If no previous update exists (e.g., after match 1), set `prev_rank` to `null` or equal to `rank`.
2. **Sorting**:
   - The response `entries` array MUST be sorted by `rank` ascending (`total_points` descending, tie-breaker: `kills` descending, then `placement_points` descending).
3. **Caching**:
   - Cache response for 5-10 seconds to optimize DB queries during high concurrency live streaming.
   - Cache MUST be invalidated immediately whenever a new match result is saved by admin/system.
