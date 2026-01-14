# What The Game - Technical Architecture

## 🏗️ System Overview

What The Game is built as a modern Rails 8 application with a service-oriented architecture, emphasizing modularity, scalability, and AI integration.

## 📐 Architecture Principles

### 1. **Service-Oriented Design**
- Core business logic isolated in service objects
- Controllers remain thin, delegating to services
- Clear separation between platform integrations and business logic

### 2. **API-First**
- Every feature accessible via API
- Supports future mobile apps, third-party integrations
- JSON responses with consistent error handling

### 3. **AI-Native Architecture**
- AI services treated as first-class components
- Multiple AI provider support (OpenAI, Anthropic, local models)
- Fallback mechanisms when AI services unavailable

### 4. **Privacy-First**
- Sensitive data encrypted at rest
- OAuth tokens never exposed to frontend
- User data analysis can happen locally

### 5. **Extensible & Modular**
- Plugin architecture for new gaming platforms
- Swappable AI backends
- Event-driven for future feature additions

## 🗂️ System Components

### Core Application (Rails 8)

```
┌─────────────────────────────────────────────────────────────┐
│                       Rails Application                      │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Controllers  │  │    Models    │  │    Views     │      │
│  │              │  │              │  │              │      │
│  │ - Games      │  │ - User       │  │ - HTML/ERB   │      │
│  │ - UserGames  │  │ - Game       │  │ - JSON       │      │
│  │ - Recommend. │  │ - UserGame   │  │ - Turbo      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Service Layer                          │    │
│  │                                                       │    │
│  │  ┌──────────────────┐    ┌────────────────────┐    │    │
│  │  │  Game Platforms  │    │   AI Services      │    │    │
│  │  │                  │    │                    │    │    │
│  │  │ - Steam          │    │ - Recommendations  │    │    │
│  │  │ - GOG            │    │ - NLP Search       │    │    │
│  │  │ - Epic           │    │ - Review Analysis  │    │    │
│  │  │ - Xbox           │    │ - Backlog Optimizer│    │    │
│  │  │ - PlayStation    │    │ - Pattern Analysis │    │    │
│  │  └──────────────────┘    └────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Background Jobs                        │    │
│  │                                                       │    │
│  │  - Library Sync Jobs                                 │    │
│  │  - Recommendation Generation                         │    │
│  │  - Price Tracking                                    │    │
│  │  - Data Enrichment                                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Data Layer

#### PostgreSQL Database
- **Primary Storage**: User data, games, relationships
- **JSONB Fields**: Flexible metadata storage
- **Full-Text Search**: Game search capabilities
- **Triggers**: Automatic timestamp and audit logging

#### Redis Cache
- **Session Storage**: User sessions
- **API Response Cache**: Platform API responses (with TTL)
- **Rate Limiting**: Track API usage
- **Background Job Queue**: Solid Queue (Rails 8)

### External Integrations

```
┌────────────────────────────────────────────────────────────┐
│                   External Services                         │
├────────────────────────────────────────────────────────────┤
│                                                              │
│  Gaming Platforms          AI Services      Data Sources    │
│  ┌──────────────┐         ┌──────────┐     ┌──────────┐   │
│  │ Steam API    │         │ OpenAI   │     │ IGDB     │   │
│  │ GOG API      │         │ Claude   │     │ RAWG     │   │
│  │ Epic API     │         │ Local LLM│     │ HowLong  │   │
│  │ Xbox API     │         └──────────┘     │ ToBeat   │   │
│  │ PSN API      │                          └──────────┘   │
│  └──────────────┘                                          │
│                                                              │
└────────────────────────────────────────────────────────────┘
```

## 📊 Data Models

### Core Entities

#### User
```ruby
- id: uuid (primary key)
- email: string (unique)
- username: string (unique)
- encrypted_password: string
- preferences: jsonb (AI preferences, display settings)
- gaming_profile: jsonb (play style, favorite genres)
- created_at, updated_at: timestamp
```

#### Game
```ruby
- id: uuid (primary key)
- title: string
- normalized_title: string (for deduplication)
- description: text
- platform: string (primary platform)
- external_id: string (platform-specific ID)
- release_date: date
- genre: string[]
- tags: string[]
- developer: string
- publisher: string
- metacritic_score: integer
- average_playtime: decimal (hours)
- metadata: jsonb (cover art, screenshots, videos)
- created_at, updated_at: timestamp

Indexes:
- normalized_title (for deduplication)
- external_id + platform (unique)
- genre (GIN index for array queries)
- Full-text search index on title + description
```

#### UserGame
```ruby
- id: uuid (primary key)
- user_id: uuid (foreign key)
- game_id: uuid (foreign key)
- status: enum (backlog, playing, completed, abandoned, wishlist)
- hours_played: decimal
- completion_percentage: integer (0-100)
- priority: integer (1-10)
- notes: text
- rating: integer (1-5)
- started_at: timestamp
- completed_at: timestamp
- last_played_at: timestamp
- play_sessions: jsonb[] (session history)
- achievements_unlocked: integer
- total_achievements: integer
- created_at, updated_at: timestamp

Indexes:
- user_id + game_id (unique)
- user_id + status
- user_id + priority
- last_played_at
```

#### GameService
```ruby
- id: uuid (primary key)
- user_id: uuid (foreign key)
- service_name: enum (steam, gog, epic, xbox, psn)
- external_user_id: string
- access_token: text (encrypted)
- refresh_token: text (encrypted)
- token_expires_at: timestamp
- last_synced_at: timestamp
- sync_enabled: boolean
- metadata: jsonb (platform-specific data)
- created_at, updated_at: timestamp

Indexes:
- user_id + service_name (unique)
```

#### Recommendation
```ruby
- id: uuid (primary key)
- user_id: uuid (foreign key)
- game_id: uuid (foreign key)
- score: decimal (0.0-1.0)
- reason: text
- reasoning_factors: jsonb (breakdown of why)
- ai_model: string (e.g., "gpt-4", "claude-3")
- context: jsonb (mood, time available, etc.)
- status: enum (pending, accepted, dismissed)
- generated_at: timestamp
- expires_at: timestamp
- created_at, updated_at: timestamp

Indexes:
- user_id + score (desc)
- user_id + status
- generated_at (for cleanup)
```

### Additional Models (Future)

#### PlaySession
```ruby
- id: uuid
- user_id: uuid
- game_id: uuid
- started_at: timestamp
- ended_at: timestamp
- duration: interval
- platform_tracked: boolean
- metadata: jsonb
```

#### PriceAlert
```ruby
- id: uuid
- user_id: uuid
- game_id: uuid
- target_price: decimal
- current_price: decimal
- platform: string
- triggered: boolean
```

#### FriendConnection
```ruby
- id: uuid
- user_id: uuid
- friend_id: uuid
- status: enum
- created_at: timestamp
```

## 🔧 Service Architecture

### Platform Integration Services

Located in `app/services/game_platforms/`

#### Base Platform Interface
```ruby
class GamePlatforms::BasePlatform
  def fetch_library           # Get user's full library
  def fetch_game_details(id)  # Get specific game info
  def sync_library            # Sync with database
  def configured?             # Check if credentials valid
  def rate_limit_status       # Monitor API usage
end
```

#### Platform-Specific Implementations

**Steam Platform** (`steam_platform.rb`)
- Uses Steam Web API
- Requires API key only (no OAuth)
- Provides rich game data, playtime, achievements
- Rate limit: ~200 requests per 5 minutes

**GOG Platform** (`gog_platform.rb`)
- Uses GOG Galaxy API
- Requires OAuth 2.0
- Access to owned games, playtime
- Rate limit: TBD

**Epic Platform** (`epic_platform.rb`)
- Uses Epic Games Services API
- Requires OAuth 2.0
- Library access, playtime tracking
- Rate limit: TBD

### AI Service Architecture

Located in `app/services/ai_services/`

#### Recommendation Service
```ruby
class AiServices::RecommendationService
  def initialize(user, provider: :auto)
    @user = user
    @provider = select_provider(provider)
  end
  
  def generate_recommendations(limit:, context: {})
    # Analyze user library
    # Generate prompt with context
    # Call AI provider
    # Parse and score results
    # Save to database
  end
  
  def explain_recommendation(recommendation)
    # Generate detailed explanation
  end
end
```

#### Natural Language Search
```ruby
class AiServices::SemanticSearchService
  def search(query)
    # Convert natural language to structured query
    # Use embeddings for semantic matching
    # Return ranked results
  end
end
```

#### Review Analysis Service
```ruby
class AiServices::ReviewAnalysisService
  def analyze_game(game)
    # Fetch reviews from multiple sources
    # Sentiment analysis
    # Key theme extraction
    # Generate summary
  end
end
```

#### Backlog Optimizer
```ruby
class AiServices::BacklogOptimizerService
  def optimize(user)
    # Analyze user patterns
    # Consider time constraints
    # Score each backlog game
    # Generate play order
  end
end
```

### AI Provider Abstraction

```ruby
module AiServices
  module Providers
    class Base
      def complete(prompt, options = {})
        raise NotImplementedError
      end
      
      def embed(text)
        raise NotImplementedError
      end
    end
    
    class OpenAI < Base
      # OpenAI API implementation
    end
    
    class Anthropic < Base
      # Anthropic API implementation
    end
    
    class LocalLLM < Base
      # Ollama or similar local model
    end
  end
end
```

## 🔄 Background Job System

Using Solid Queue (Rails 8 default)

### Job Types

#### Sync Jobs
```ruby
class LibrarySyncJob < ApplicationJob
  queue_as :default
  
  def perform(user_id, service_name)
    # Fetch library from platform
    # Update or create games
    # Update user_games
    # Log sync results
  end
end
```

#### Recommendation Jobs
```ruby
class GenerateRecommendationsJob < ApplicationJob
  queue_as :ai_processing
  
  def perform(user_id, options = {})
    # Generate fresh recommendations
    # Expire old ones
  end
end
```

#### Price Tracking
```ruby
class PriceCheckJob < ApplicationJob
  queue_as :low_priority
  
  def perform
    # Check prices for wishlist games
    # Trigger alerts if below threshold
  end
end
```

## 🔐 Security Architecture

### Authentication
- Session-based authentication (Rails default)
- Optional JWT tokens for API access
- OAuth 2.0 for platform integrations

### Authorization
- Role-based access control (future)
- Users can only access their own data
- API rate limiting per user

### Data Protection
- **Encryption at Rest**: Platform tokens encrypted using Rails credentials
- **Encryption in Transit**: HTTPS only
- **API Key Management**: Environment variables, never in code
- **Sensitive Data**: Never logged or exposed in errors

### Rate Limiting
```ruby
class ApiRateLimiter
  # 100 requests per minute for authenticated users
  # 20 requests per minute for unauthenticated
  # Exponential backoff for AI service calls
end
```

## 🚀 Deployment Architecture

### Production Stack (Recommended)

```
┌─────────────────────────────────────────────────────────┐
│                      Load Balancer                       │
│                     (nginx/caddy)                        │
└─────────────────────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
┌────────▼────────┐ ┌───────▼───────┐ ┌───────▼───────┐
│  Rails Server 1 │ │ Rails Server 2│ │ Rails Server 3│
│    (Puma)       │ │    (Puma)     │ │    (Puma)     │
└─────────────────┘ └───────────────┘ └───────────────┘
         │                  │                  │
         └──────────────────┼──────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
┌────────▼────────┐ ┌───────▼───────┐ ┌───────▼───────┐
│   PostgreSQL    │ │     Redis     │ │   S3/Storage  │
│    (Primary)    │ │   (Cache +    │ │   (Assets)    │
│                 │ │    Queue)     │ │               │
└─────────────────┘ └───────────────┘ └───────────────┘
```

### Deployment Options

1. **Docker + Kamal** (Included)
   - Simple deployment to any VPS
   - Configuration in `config/deploy.yml`
   - Zero-downtime deployments

2. **Heroku**
   - Easy setup with buildpacks
   - Managed PostgreSQL and Redis
   - Background workers with Hobby plan

3. **AWS/GCP**
   - Elastic Beanstalk or App Engine
   - RDS for PostgreSQL
   - ElastiCache for Redis

4. **Fly.io** (Recommended for MVP)
   - Global edge deployment
   - Managed PostgreSQL
   - Simple scaling

## 📊 Performance Considerations

### Caching Strategy

1. **HTTP Caching**: ETags for API responses
2. **Fragment Caching**: Game cards, library views
3. **Russian Doll Caching**: Nested game data
4. **Query Caching**: Frequently accessed user data
5. **API Response Caching**: Platform API calls (TTL: 1 hour)

### Database Optimization

1. **Indexes**: Strategic indexes on all foreign keys and query patterns
2. **Connection Pooling**: Configured in database.yml
3. **Query Optimization**: Use `includes` to avoid N+1
4. **Materialized Views**: For complex analytics (future)
5. **Partitioning**: Time-based partitioning for play_sessions (future)

### Background Processing

1. **Job Prioritization**: Critical, normal, low queues
2. **Retry Logic**: Exponential backoff for API failures
3. **Timeout Protection**: Long-running jobs have timeouts
4. **Monitoring**: Track job success/failure rates

## 🔍 Monitoring & Observability

### Metrics to Track
- Request latency (p50, p95, p99)
- Database query performance
- Background job processing time
- AI API response times and costs
- Platform API success rates
- Cache hit rates
- User engagement metrics

### Logging Strategy
- Structured JSON logging
- Log levels appropriately
- Never log sensitive data (tokens, passwords)
- Track AI prompts and responses (opt-in)

### Error Tracking
- Sentry or similar for production errors
- Slack/email notifications for critical issues
- AI service failure alerts

## 🧪 Testing Strategy

### Test Pyramid

```
        ┌─────────────┐
        │   E2E Tests │  (Few - Critical paths)
        └─────────────┘
       ┌───────────────┐
       │Integration    │  (Some - API endpoints)
       │    Tests      │
       └───────────────┘
      ┌─────────────────┐
      │   Unit Tests    │  (Many - Services, models)
      └─────────────────┘
```

### Testing Approach

1. **Models**: Validate business logic, associations, validations
2. **Services**: Mock external APIs, test error handling
3. **Controllers**: Test request/response, authentication
4. **Integration**: Test full user flows
5. **AI Services**: Use recorded responses (VCR), test prompt engineering

## 🔄 API Versioning

Future-proof API design:
- `/api/v1/games`
- `/api/v2/games` (when breaking changes needed)
- Version in Accept header as alternative

## 📦 Extensibility Points

### Plugin System (Future)
```ruby
# Allow community-built platform integrations
module GamePlatforms
  class Registry
    def self.register(platform_class)
      # Add new platform
    end
  end
end
```

### Webhooks
```ruby
# Allow users to react to events
POST /api/webhooks
{
  "events": ["game.completed", "recommendation.generated"],
  "url": "https://user-app.com/webhook"
}
```

### Import/Export
- Export library data (JSON, CSV)
- Import from other services (Backloggd, etc.)

## 🚦 Scalability Path

### Current (MVP): Single Server
- Handles ~1000 concurrent users
- Vertical scaling first

### Growth: Horizontal Scaling
- Multiple app servers behind load balancer
- Redis for session management
- Background job workers scaled independently

### Scale: Microservices (If Needed)
- AI services as separate microservice
- Platform integrations as separate services
- Event-driven architecture

## 📝 Configuration Management

### Environment Variables
```bash
# Database
DATABASE_URL=

# Platform APIs
STEAM_API_KEY=
GOG_CLIENT_ID=
GOG_CLIENT_SECRET=
EPIC_CLIENT_ID=
EPIC_CLIENT_SECRET=

# AI Services
OPENAI_API_KEY=
ANTHROPIC_API_KEY=

# Storage
S3_BUCKET=
S3_ACCESS_KEY=
S3_SECRET_KEY=

# Monitoring
SENTRY_DSN=

# Feature Flags
ENABLE_AI_RECOMMENDATIONS=true
ENABLE_PRICE_TRACKING=false
```

### Feature Flags
Use Rails credentials or gem like `flipper` for feature toggles

## 🔮 Future Technical Enhancements

1. **GraphQL API**: More flexible than REST for complex queries
2. **WebSocket Support**: Real-time updates (friend playing, deal alerts)
3. **Offline Support**: PWA with service workers
4. **Mobile Apps**: Native iOS/Android with shared API
5. **Machine Learning**: Custom recommendation models
6. **Vector Database**: Better semantic search (Pinecone, Weaviate)
7. **CDN**: Global asset delivery
8. **Edge Functions**: Serverless for specific features

---

This architecture balances simplicity for MVP development with extensibility for future growth. We start with Rails conventions and expand thoughtfully as needs arise.
