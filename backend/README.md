# Brainstorming Application - Spring Boot Backend

## Project Structure

```
backend/
├── src/main/java/com/brainstorming/
│   ├── BrainstormingApplication.java    # Main application entry point
│   ├── config/                          # Configuration classes
│   │   ├── CorsConfig.java              # CORS configuration
│   │   └── SecurityConfig.java          # Spring Security configuration
│   ├── controller/                      # REST Controllers
│   │   ├── AuthController.java          # Authentication endpoints
│   │   ├── EventController.java         # Event management
│   │   ├── TeamController.java          # Team management
│   │   ├── TopicController.java         # Topic management
│   │   ├── SessionController.java       # Brainstorming sessions
│   │   ├── IdeaController.java          # Ideas management
│   │   └── UserController.java          # User management
│   ├── dto/                             # Data Transfer Objects
│   ├── entity/                          # JPA Entities
│   ├── exception/                       # Custom exceptions & handlers
│   ├── mapper/                          # MapStruct mappers
│   └── repository/                      # Spring Data JPA repositories
└── src/main/resources/
    └── application.yml                  # Application configuration
```

## Prerequisites

- Java 21
- Maven 3.8+
- MySQL 8.0+

## Setup

1. **Database Setup**
   ```bash
   mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS brainstorming_app;"
   mysql -u root -p brainstorming_app < ../brainstorming_app.sql
   ```

2. **Configure Environment**
   
   Update `src/main/resources/application.yml` with your database credentials, or set environment variables:
   ```bash
   export DB_PASSWORD=your_mysql_password
   export JWT_SECRET=your_jwt_secret_key
   ```

3. **Build & Run**
   ```bash
   cd backend
   ./mvnw clean install
   ./mvnw spring-boot:run
   ```

4. **Access API**
   
   The API will be available at `http://localhost:8080/api`

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - User login
- `GET /api/auth/profile` - Get current user profile

### Events
- `GET /api/events` - List all events
- `POST /api/events` - Create event
- `GET /api/events/{id}` - Get event details
- `PUT /api/events/{id}` - Update event
- `DELETE /api/events/{id}` - Delete event

### Teams
- `GET /api/teams` - List all teams
- `POST /api/teams` - Create team
- `GET /api/teams/{id}` - Get team details
- `GET /api/teams/{id}/members` - Get team members
- `POST /api/teams/{id}/members/{userId}` - Add member
- `DELETE /api/teams/{id}/members/{userId}` - Remove member

### Sessions
- `GET /api/sessions` - List all sessions
- `POST /api/sessions` - Create session
- `POST /api/sessions/{id}/start` - Start session
- `POST /api/sessions/{id}/pause` - Pause session
- `POST /api/sessions/{id}/complete` - Complete session

### Ideas
- `GET /api/ideas` - List all ideas
- `POST /api/ideas` - Create idea
- `PUT /api/ideas/{id}` - Update idea
- `DELETE /api/ideas/{id}` - Delete idea

## TODO

- [ ] Implement service layer with business logic
- [ ] Add JWT authentication filter
- [ ] Implement all controller methods
- [ ] Add unit and integration tests
- [ ] Add API documentation (Swagger/OpenAPI)
