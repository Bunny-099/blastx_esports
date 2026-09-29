# Player Ranking & XP Progression System - API & Backend Requirements

This document specifies the architecture, rank thresholds, calculation rules, API contracts, idempotency, and error handling for the **Player Ranking + XP Progression System** in Blastx Esports.

---

## 1. Rank System Overview & Core Principles

- **Authoritative Source of Truth**: The backend database MUST be the single authoritative source of truth for `totalXP` and player `rank`.
- **Security Rule**: The frontend NEVER directly sends updated `totalXP` or `rank` to the backend. XP can only be earned and modified through server-verified actions (such as claiming completed challenge rewards).
- **Client Presentation**: The frontend contains a matching `RankSystem` utility for instant local visual response, progress bar renders, offline display, and smooth fallback calculations.

---

## 2. Central Rank Configuration & XP Thresholds

The system features **14 ranks** with progressive XP requirements.

| Rank Number | Rank Name | Min Total XP | XP Required for Next Rank |
|:-----------:|:----------|:-------------|:--------------------------|
| **1** | Rookie | 0 XP | 500 XP |
| **2** | Recruit | 500 XP | 1,000 XP (At 1,500 XP) |
| **3** | Fighter | 1,500 XP | 1,500 XP (At 3,000 XP) |
| **4** | Warrior | 3,000 XP | 2,500 XP (At 5,500 XP) |
| **5** | Veteran | 5,500 XP | 3,500 XP (At 9,000 XP) |
| **6** | Elite | 9,000 XP | 5,000 XP (At 14,000 XP) |
| **7** | Specialist | 14,000 XP | 6,000 XP (At 20,000 XP) |
| **8** | Champion | 20,000 XP | 8,000 XP (At 28,000 XP) |
| **9** | Master | 28,000 XP | 10,000 XP (At 38,000 XP) |
| **10** | Grandmaster | 38,000 XP | 12,000 XP (At 50,000 XP) |
| **11** | Legend | 50,000 XP | 15,000 XP (At 65,000 XP) |
| **12** | Mythic | 65,000 XP | 20,000 XP (At 85,000 XP) |
| **13** | Immortal | 85,000 XP | 25,000 XP (At 110,000 XP) |
| **14** | Apex | 110,000 XP | *Max Rank Achieved* |

---

## 3. XP & Rank Calculation Rules

Given a player's `totalXP`:

1. **Negative / Invalid XP**: Clamped to `0 XP`.
2. **Current Rank**: The highest rank tier $R$ where $\text{minXP}_R \le \text{totalXP}$.
3. **Next Rank**: Rank tier $R + 1$, or `null` if $\text{totalXP} \ge 110,000$ (Apex / Rank 14).
4. **XP Remaining**:
   $$\text{xpRemaining} = \begin{cases} \text{minXP}_{\text{nextRank}} - \text{totalXP} & \text{if Next Rank exists} \\ 0 & \text{if Rank 14 (Apex)} \end{cases}$$
5. **Progress Percentage**:
   $$\text{progress} = \begin{cases} \dfrac{\text{totalXP} - \text{minXP}_{\text{currentRank}}}{\text{minXP}_{\text{nextRank}} - \text{minXP}_{\text{currentRank}}} & \text{if Next Rank exists} \\ 1.0 & \text{if Rank 14 (Apex)} \end{cases}$$

---

## 4. API Endpoints Contract

### 4.1. Get Player Rank

Retrieves the current player's rank progress, XP breakdown, and next rank information.

- **HTTP Method**: `GET`
- **Endpoint**: `/v1/users/me/rank` (or `/v1/users/{userId}/rank`)
- **Headers**:
  - `Authorization: Bearer <TOKEN>`

#### Success Response (`200 OK`)

```json
{
  "success": true,
  "data": {
    "userId": "usr_987654321",
    "totalXP": 7000,
    "rank": {
      "number": 5,
      "name": "Veteran",
      "minXP": 5500,
      "maxXP": 9000
    },
    "nextRank": {
      "number": 6,
      "name": "Elite",
      "minXP": 9000
    },
    "xpRemaining": 2000,
    "progress": 0.4286,
    "isMaxRank": false
  }
}
```

For Rank 14 (Apex):

```json
{
  "success": true,
  "data": {
    "userId": "usr_987654321",
    "totalXP": 115000,
    "rank": {
      "number": 14,
      "name": "Apex",
      "minXP": 110000,
      "maxXP": null
    },
    "nextRank": null,
    "xpRemaining": 0,
    "progress": 1.0,
    "isMaxRank": true
  }
}
```

---

### 4.2. Claim Challenge XP

Claims reward XP for a completed challenge, updates player total XP, and recalculates rank.

- **HTTP Method**: `POST`
- **Endpoint**: `/v1/challenges/{challengeId}/claim`
- **Headers**:
  - `Authorization: Bearer <TOKEN>`

#### Standard Response - No Rank Up (`200 OK`)

```json
{
  "success": true,
  "data": {
    "challengeId": "ch_daily_01",
    "claimedXP": 500,
    "totalXP": 7500,
    "rank": {
      "number": 5,
      "name": "Veteran",
      "minXP": 5500,
      "nextRankMinXP": 9000
    },
    "rankChanged": false
  }
}
```

#### Promotion Response - Rank Up Triggered (`200 OK`)

```json
{
  "success": true,
  "data": {
    "challengeId": "ch_special_booyah",
    "claimedXP": 2000,
    "totalXP": 9000,
    "rank": {
      "number": 6,
      "name": "Elite",
      "minXP": 9000,
      "nextRankMinXP": 14000
    },
    "rankChanged": true,
    "previousRank": {
      "number": 5,
      "name": "Veteran",
      "minXP": 5500
    }
  }
}
```

---

## 5. Duplicate Claim Prevention & Idempotency Rules

1. **Idempotency**: The backend MUST check if the player has already claimed the reward for `{challengeId}`.
2. **Duplicate Claim Attempt**:
   - If `is_claimed == true` in DB, return `400 Bad Request` or `409 Conflict`.
   - The payload response must indicate the challenge was already claimed and MUST NOT increase `totalXP`.

#### Duplicate Claim Error Response (`400 Bad Request` / `409 Conflict`)

```json
{
  "success": false,
  "error": {
    "code": "CHALLENGE_ALREADY_CLAIMED",
    "message": "Reward for this challenge has already been claimed."
  }
}
```

---

## 6. Standard Error Responses

| HTTP Code | Error Code | Description | Example JSON |
|:---------:|:-----------|:------------|:-------------|
| **401** | `UNAUTHORIZED` | Missing or invalid auth token | `{"success": false, "error": {"code": "UNAUTHORIZED", "message": "Authentication required."}}` |
| **404** | `CHALLENGE_NOT_FOUND` | Invalid challenge ID | `{"success": false, "error": {"code": "CHALLENGE_NOT_FOUND", "message": "Challenge does not exist."}}` |
| **400** | `CHALLENGE_NOT_COMPLETED` | Challenge requirements not met | `{"success": false, "error": {"code": "CHALLENGE_NOT_COMPLETED", "message": "Challenge is not completed yet."}}` |
| **400** | `CHALLENGE_ALREADY_CLAIMED` | Attempted duplicate claim | `{"success": false, "error": {"code": "CHALLENGE_ALREADY_CLAIMED", "message": "Reward already claimed."}}` |
| **500** | `INTERNAL_SERVER_ERROR` | Database or server failure | `{"success": false, "error": {"code": "INTERNAL_SERVER_ERROR", "message": "An error occurred while processing claim."}}` |

---

## 7. Database Persistence & Consistency Requirements

1. **User Table Schema**:
   - `xp` (Integer, DEFAULT 0, UNSIGNED/CHECK >= 0)
   - `rank` (Integer, DEFAULT 1, CHECK between 1 and 14)
2. **User Challenge Claim Junction Table**:
   - `user_id` (UUID/String)
   - `challenge_id` (UUID/String)
   - `claimed_at` (Timestamp)
   - *PRIMARY KEY / UNIQUE INDEX* on `(user_id, challenge_id)` to prevent duplicate claims at DB constraint level.
3. **Transaction Safety**: Adding XP and marking challenge as claimed MUST occur within an atomic database transaction.
