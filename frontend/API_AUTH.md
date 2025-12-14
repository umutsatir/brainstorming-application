# Authentication & User Profile API

## Environment Variables

Create a `.env.local` file in the `frontend` directory with the following variables:

```
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=brainstorming_app
JWT_SECRET=your-secret-key-change-in-production
```

## API Endpoints

### 1. Register User

**POST** `/api/auth/register`

Register a new user account.

**Request Body:**

```json
{
    "full_name": "John Doe",
    "email": "john@example.com",
    "password": "securepassword123",
    "phone": "+1234567890", // optional
    "role": "TEAM_MEMBER" // optional, defaults to TEAM_MEMBER
}
```

**Response (201):**

```json
{
    "user": {
        "id": 1,
        "full_name": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "role": "TEAM_MEMBER",
        "status": "ACTIVE",
        "created_at": "2025-01-01T00:00:00.000Z",
        "updated_at": "2025-01-01T00:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Responses:**

-   `400` - Missing required fields
-   `409` - User with email already exists
-   `500` - Internal server error

---

### 2. Login

**POST** `/api/auth/login`

Authenticate a user and receive a JWT token.

**Request Body:**

```json
{
    "email": "john@example.com",
    "password": "securepassword123"
}
```

**Response (200):**

```json
{
    "user": {
        "id": 1,
        "full_name": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "role": "TEAM_MEMBER",
        "status": "ACTIVE",
        "created_at": "2025-01-01T00:00:00.000Z",
        "updated_at": "2025-01-01T00:00:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Error Responses:**

-   `400` - Missing email or password
-   `401` - Invalid email or password
-   `403` - Account is not active
-   `500` - Internal server error

---

### 3. Get User Profile

**GET** `/api/auth/profile`

Get the current authenticated user's profile.

**Headers:**

```
Authorization: Bearer <token>
```

**Response (200):**

```json
{
    "user": {
        "id": 1,
        "full_name": "John Doe",
        "email": "john@example.com",
        "phone": "+1234567890",
        "role": "TEAM_MEMBER",
        "status": "ACTIVE",
        "created_at": "2025-01-01T00:00:00.000Z",
        "updated_at": "2025-01-01T00:00:00.000Z"
    }
}
```

**Error Responses:**

-   `401` - Unauthorized (missing or invalid token)
-   `404` - User not found
-   `500` - Internal server error

---

### 4. Update User Profile

**PUT** `/api/auth/profile`

Update the current authenticated user's profile.

**Headers:**

```
Authorization: Bearer <token>
```

**Request Body:**

```json
{
    "full_name": "Jane Doe", // optional
    "phone": "+9876543210" // optional
}
```

**Response (200):**

```json
{
    "user": {
        "id": 1,
        "full_name": "Jane Doe",
        "email": "john@example.com",
        "phone": "+9876543210",
        "role": "TEAM_MEMBER",
        "status": "ACTIVE",
        "created_at": "2025-01-01T00:00:00.000Z",
        "updated_at": "2025-01-01T01:00:00.000Z"
    }
}
```

**Error Responses:**

-   `400` - No fields to update
-   `401` - Unauthorized (missing or invalid token)
-   `404` - User not found
-   `500` - Internal server error

---

## User Roles

-   `EVENT_MANAGER` - Can manage events
-   `TEAM_LEADER` - Can lead teams
-   `TEAM_MEMBER` - Regular team member (default)

## User Status

-   `ACTIVE` - User can log in and use the system
-   `INACTIVE` - User account is disabled
-   `INVITED` - User has been invited but not yet activated

## Authentication

All protected endpoints require a JWT token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

Tokens expire after 7 days. To get a new token, the user must log in again.
