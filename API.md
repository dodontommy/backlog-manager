# API Documentation

This document describes the planned API structure for What The Game.

## Overview

The application provides endpoints for managing game libraries, getting recommendations, and integrating with various gaming platforms.

## Models

### User
Represents a user of the application.

**Attributes:**
- `email` (string) - User's email address
- `username` (string) - User's display name

**Associations:**
- `has_many :user_games` - Games in user's library
- `has_many :games, through: :user_games`
- `has_many :game_services` - Connected gaming platform accounts
- `has_many :recommendations` - AI-generated recommendations

### Game
Represents a video game across all platforms.

**Attributes:**
- `title` (string) - Game title
- `description` (text) - Game description
- `platform` (string) - Gaming platform (steam, gog, epic, etc.)
- `external_id` (string) - Platform-specific game ID
- `release_date` (date) - Release date
- `genre` (string) - Game genre
- `developer` (string) - Developer name
- `publisher` (string) - Publisher name

**Associations:**
- `has_many :user_games`
- `has_many :users, through: :user_games`
- `has_many :recommendations`

### UserGame
Join table representing a game in a user's library.

**Attributes:**
- `status` (string) - Current status: backlog, playing, completed, abandoned, wishlist
- `hours_played` (decimal) - Time spent playing
- `completion_percentage` (integer) - Progress (0-100)
- `priority` (integer) - User priority (1-10)
- `notes` (text) - User notes

**Associations:**
- `belongs_to :user`
- `belongs_to :game`

### GameService
Represents a connection to a gaming platform.

**Attributes:**
- `service_name` (string) - Platform name: steam, gog, epic
- `access_token` (text) - OAuth access token (encrypted)
- `refresh_token` (text) - OAuth refresh token (encrypted)
- `token_expires_at` (datetime) - Token expiration

**Associations:**
- `belongs_to :user`

### Recommendation
AI-generated game recommendation.

**Attributes:**
- `score` (decimal) - Recommendation score (0.0-1.0)
- `reason` (text) - Explanation for recommendation
- `ai_model` (string) - AI model used

**Associations:**
- `belongs_to :user`
- `belongs_to :game`

## API Endpoints (Planned)

### Games

**GET /games**
List all games.

Query Parameters:
- `page` (integer) - Page number for pagination
- `per_page` (integer) - Items per page (default: 25)
- `genre` (string) - Filter by genre
- `platform` (string) - Filter by platform

Response:
```json
{
  "games": [
    {
      "id": 1,
      "title": "Example Game",
      "platform": "steam",
      "genre": "RPG",
      "release_date": "2024-01-15"
    }
  ],
  "pagination": {
    "current_page": 1,
    "total_pages": 10,
    "total_count": 250
  }
}
```

**GET /games/:id**
Get details for a specific game.

Response:
```json
{
  "id": 1,
  "title": "Example Game",
  "description": "An epic adventure...",
  "platform": "steam",
  "external_id": "12345",
  "release_date": "2024-01-15",
  "genre": "RPG",
  "developer": "Game Studio",
  "publisher": "Publisher Inc"
}
```

### User Games (Backlog)

**GET /user_games**
Get current user's game library.

Query Parameters:
- `status` (string) - Filter by status
- `sort` (string) - Sort field: title, hours_played, priority
- `order` (string) - asc or desc

Response:
```json
{
  "user_games": [
    {
      "id": 1,
      "game": {
        "id": 1,
        "title": "Example Game"
      },
      "status": "backlog",
      "hours_played": 10.5,
      "completion_percentage": 45,
      "priority": 8
    }
  ]
}
```

**POST /user_games**
Add a game to user's library.

Request:
```json
{
  "game_id": 1,
  "status": "backlog",
  "priority": 5
}
```

**PATCH /user_games/:id**
Update game in library.

Request:
```json
{
  "status": "playing",
  "hours_played": 15.0,
  "completion_percentage": 60
}
```

### Recommendations

**GET /recommendations**
Get AI-generated recommendations.

Query Parameters:
- `limit` (integer) - Number of recommendations (default: 5)

Response:
```json
{
  "recommendations": [
    {
      "id": 1,
      "game": {
        "id": 1,
        "title": "Recommended Game"
      },
      "score": 0.95,
      "reason": "Based on your love of RPGs and completion of similar titles...",
      "ai_model": "gpt-4"
    }
  ]
}
```

**POST /recommendations/generate**
Generate new recommendations.

Request:
```json
{
  "limit": 10,
  "preferences": {
    "genres": ["RPG", "Adventure"],
    "max_hours": 50
  }
}
```

## Game Platform Integration

### Steam

**POST /game_services/steam/connect**
Initialize Steam OAuth connection.

**GET /game_services/steam/callback**
OAuth callback handler.

**POST /game_services/steam/sync**
Sync library from Steam.

### GOG

**POST /game_services/gog/connect**
Initialize GOG OAuth connection.

**GET /game_services/gog/callback**
OAuth callback handler.

**POST /game_services/gog/sync**
Sync library from GOG.

### Epic Games

**POST /game_services/epic/connect**
Initialize Epic Games OAuth connection.

**GET /game_services/epic/callback**
OAuth callback handler.

**POST /game_services/epic/sync**
Sync library from Epic Games.

## Service Classes

### GamePlatforms::BasePlatform
Base class for platform integrations.

Methods:
- `fetch_library` - Retrieve user's game library
- `fetch_game_details(game_id)` - Get details for specific game
- `configured?` - Check if service is configured

### AiServices::RecommendationService
AI-powered recommendation engine.

Methods:
- `generate_recommendations(limit:)` - Generate recommendations for user
- `recommend_game(game)` - Evaluate specific game for user

## Error Responses

All errors follow this format:
```json
{
  "error": {
    "code": "validation_error",
    "message": "Invalid parameters",
    "details": {
      "field": "status",
      "issue": "must be one of: backlog, playing, completed, abandoned, wishlist"
    }
  }
}
```

Common error codes:
- `validation_error` - Invalid input data
- `not_found` - Resource not found
- `unauthorized` - Authentication required
- `forbidden` - Insufficient permissions
- `service_unavailable` - External service error

## Authentication (Future)

Authentication will use session-based auth or JWT tokens.

Headers:
```
Authorization: Bearer <token>
```

## Rate Limiting (Future)

API rate limits:
- 100 requests per minute for authenticated users
- 20 requests per minute for unauthenticated users

Rate limit headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640995200
```
