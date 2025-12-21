# Teams API

Teams endpoint'leri için dokümantasyon.

## Endpoints

### 1. Create Team

**POST** `/api/events/[eventId]/teams`

Create a new team for an event.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "name": "Team Alpha",
  "leader_id": 2,
  "member_ids": [3, 4, 5, 6, 7]  // optional, max 5 members
}
```

**Response (201):**
```json
{
  "team": {
    "id": 1,
    "event_id": 1,
    "name": "Team Alpha",
    "leader_id": 2,
    "leader": {
      "id": 2,
      "full_name": "John Leader",
      "email": "leader@example.com"
    },
    "members": [
      {
        "id": 1,
        "user_id": 3,
        "user": {
          "id": 3,
          "full_name": "Member One",
          "email": "member1@example.com"
        },
        "created_at": "2025-01-01T00:00:00.000Z"
      }
    ],
    "member_count": 5,
    "created_at": "2025-01-01T00:00:00.000Z",
    "updated_at": "2025-01-01T00:00:00.000Z"
  }
}
```

**Error Responses:**
- `400` - Missing required fields or invalid data
- `401` - Unauthorized
- `403` - Only event managers can create teams
- `404` - Event or leader not found
- `500` - Internal server error

**Notes:**
- Maximum 5 members allowed (1 leader + 5 members = 6 total for 6-3-5 method)
- Leader cannot be added as a member
- Only EVENT_MANAGER (event owner) can create teams

---

### 2. List Teams for Event

**GET** `/api/events/[eventId]/teams`

List all teams for a specific event.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "teams": [
    {
      "id": 1,
      "event_id": 1,
      "name": "Team Alpha",
      "leader_id": 2,
      "leader": {
        "id": 2,
        "full_name": "John Leader",
        "email": "leader@example.com"
      },
      "member_count": 5,
      "created_at": "2025-01-01T00:00:00.000Z",
      "updated_at": "2025-01-01T00:00:00.000Z"
    }
  ]
}
```

**Error Responses:**
- `400` - Invalid event ID
- `401` - Unauthorized
- `500` - Internal server error

---

### 3. Get Team Details

**GET** `/api/teams/[id]`

Get detailed information about a team including all members.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "team": {
    "id": 1,
    "event_id": 1,
    "name": "Team Alpha",
    "leader_id": 2,
    "leader": {
      "id": 2,
      "full_name": "John Leader",
      "email": "leader@example.com"
    },
    "members": [
      {
        "id": 1,
        "user_id": 3,
        "user": {
          "id": 3,
          "full_name": "Member One",
          "email": "member1@example.com"
        },
        "created_at": "2025-01-01T00:00:00.000Z"
      }
    ],
    "member_count": 5,
    "created_at": "2025-01-01T00:00:00.000Z",
    "updated_at": "2025-01-01T00:00:00.000Z"
  }
}
```

**Error Responses:**
- `400` - Invalid team ID
- `401` - Unauthorized
- `403` - You don't have access to this team
- `404` - Team not found
- `500` - Internal server error

**Access Control:**
- Event Manager (event owner) can view any team in their event
- Team Leader can view their own team
- Team Members can view their own team

---

### 4. Update Team

**PATCH** `/api/teams/[id]`

Update team information (name or leader).

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "name": "Updated Team Name",  // optional
  "leader_id": 8                // optional
}
```

**Response (200):**
```json
{
  "team": {
    "id": 1,
    "event_id": 1,
    "name": "Updated Team Name",
    "leader_id": 8,
    "leader": {
      "id": 8,
      "full_name": "New Leader",
      "email": "newleader@example.com"
    },
    "members": [...],
    "member_count": 5,
    "created_at": "2025-01-01T00:00:00.000Z",
    "updated_at": "2025-01-01T01:00:00.000Z"
  }
}
```

**Error Responses:**
- `400` - Invalid team ID or no fields to update
- `401` - Unauthorized
- `403` - Only event managers can update teams
- `404` - Team or leader not found
- `500` - Internal server error

**Notes:**
- Only EVENT_MANAGER (event owner) can update teams

---

### 5. Delete Team

**DELETE** `/api/teams/[id]`

Delete a team and all its members.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "message": "Team deleted successfully"
}
```

**Error Responses:**
- `400` - Invalid team ID
- `401` - Unauthorized
- `403` - Only event managers can delete teams
- `404` - Team not found
- `500` - Internal server error

**Notes:**
- Only EVENT_MANAGER (event owner) can delete teams
- This will also delete all team members associations

---

### 6. Add Member to Team

**POST** `/api/teams/[id]/members`

Add a user as a member to a team.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "user_id": 9
}
```

**Response (201):**
```json
{
  "team": {
    "id": 1,
    "event_id": 1,
    "name": "Team Alpha",
    "leader_id": 2,
    "leader": {
      "id": 2,
      "full_name": "John Leader",
      "email": "leader@example.com"
    },
    "members": [
      {
        "id": 1,
        "user_id": 9,
        "user": {
          "id": 9,
          "full_name": "New Member",
          "email": "newmember@example.com"
        },
        "created_at": "2025-01-01T01:00:00.000Z"
      }
    ],
    "member_count": 1,
    "created_at": "2025-01-01T00:00:00.000Z",
    "updated_at": "2025-01-01T00:00:00.000Z"
  }
}
```

**Error Responses:**
- `400` - Invalid team ID, missing user_id, or team is full
- `401` - Unauthorized
- `403` - Only event managers can add team members
- `404` - Team or user not found
- `409` - User is already a member
- `500` - Internal server error

**Notes:**
- Maximum 5 members allowed (1 leader + 5 members = 6 total)
- Leader cannot be added as a member
- Only EVENT_MANAGER (event owner) can add members

---

### 7. Remove Member from Team

**DELETE** `/api/teams/[id]/members/[userId]`

Remove a member from a team.

**Headers:**
```
Authorization: Bearer <token>
```

**Response (200):**
```json
{
  "team": {
    "id": 1,
    "event_id": 1,
    "name": "Team Alpha",
    "leader_id": 2,
    "leader": {
      "id": 2,
      "full_name": "John Leader",
      "email": "leader@example.com"
    },
    "members": [],
    "member_count": 0,
    "created_at": "2025-01-01T00:00:00.000Z",
    "updated_at": "2025-01-01T00:00:00.000Z"
  },
  "message": "Member removed successfully"
}
```

**Error Responses:**
- `400` - Invalid team ID or user ID
- `401` - Unauthorized
- `403` - Only event managers can remove team members
- `404` - Team not found or user is not a member
- `500` - Internal server error

**Notes:**
- Only EVENT_MANAGER (event owner) can remove members

---

## Team Structure

### 6-3-5 Method Requirements

For the 6-3-5 brainstorming method:
- Each team must have exactly **6 members total**
- 1 Team Leader
- 5 Team Members
- Maximum capacity: 5 members (leader is separate)

### Team Roles

- **Team Leader**: Assigned when creating the team (`leader_id`)
- **Team Members**: Added via the members endpoint (max 5)

---

## Authorization

### Event Manager (EVENT_MANAGER)
- Can create teams for their events
- Can update teams in their events
- Can delete teams in their events
- Can add/remove members from teams in their events
- Can view all teams in their events

### Team Leader (TEAM_LEADER)
- Can view their own team details
- Cannot modify team structure

### Team Member (TEAM_MEMBER)
- Can view their own team details
- Cannot modify team structure


