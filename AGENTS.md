# Agent Guidelines for AI Gaming Backlog Manager

**Last Updated:** 2026-01-23
**Project Status:** Phase 1 (Anthropic Chat Integration) - In Development

---

## Project Overview

**AI Gaming Backlog Manager** is a web-based application that helps gamers manage their gaming backlogs and decide what to play next using AI-powered recommendations.

### The Core Problem

Gamers accumulate large game libraries across multiple platforms (Steam, GOG, Epic, etc.) but struggle to decide what to play. Existing backlog trackers are just lists - this app uses AI to analyze playing patterns and preferences to make personalized recommendations through a conversational interface.

### What Makes This Different

- **AI Chat Interface** - Users ask "what should I play?" and get personalized suggestions
- **Smart Recommendations** - Analyzes completion patterns, genres, and playing history
- **Cross-Platform Sync** - Automatic library sync from Steam (GOG/Epic planned)
- **Progress Tracking** - Status, hours played, ratings, notes per game

---

## Architecture

### High-Level Design

```
User Browser
    ↓
Rails App (UI + Controllers)
    ↓
├→ PostgreSQL (User data, backlog, chat history)
├→ Anthropic API (Claude with custom tools)
│   └→ Tools execute:
│       ├→ IGDB API (game metadata)
│       └→ Steam API (user library)
└→ Background Jobs (Solid Queue for Steam sync)
```

### Request Flow for AI Chat

```
1. User sends chat message
   ↓
2. Rails ChatController receives message
   ↓
3. ChatSession stores user message in DB
   ↓
4. AnthropicService calls Claude API with:
   - Conversation history
   - 6 custom tool definitions
   ↓
5. Claude responds with:
   - Text response → Stream to user via SSE
   - Tool call → Rails executes via ToolExecutor
   ↓
6. If tool call:
   - ToolExecutor queries DB or external API
   - Result sent back to Anthropic
   - Claude processes and continues conversation
   ↓
7. Response streamed to frontend via Server-Sent Events
   ↓
8. Stimulus controller appends to chat UI in real-time
```

### Why This Architecture?

**Anthropic Tool Use (not MCP servers):**
- MCP servers require separate HTTP hosting for production
- Tool use keeps everything in Rails (simpler deployment)
- Good enough for v1, can migrate to MCP later

**Session-based chat (not persistent threads):**
- Simpler for v1 - no thread management UI
- Most interactions are contextual ("what should I play now?")
- Can upgrade to persistent threads in Phase 6

**Solid Queue (not Sidekiq/Redis):**
- Built into Rails 8, one less service to host
- Sufficient for hobby-scale background jobs
- Easy to upgrade later if needed

---

## Data Model

### Users
```ruby
# Table: users
id (bigint, primary key)
email (string, nullable for Steam-only users)
username (string, required)
provider (string) # google_oauth2, facebook, steam
uid (string) # OAuth provider's user ID
avatar_url (string)
last_steam_sync_at (datetime)
created_at, updated_at

# Associations
has_many :identities
has_many :user_games
has_many :games, through: :user_games
has_many :chat_sessions
has_many :game_services (legacy, deprecate later)
has_many :recommendations (future)
```

### Identities (OAuth Connections)
```ruby
# Table: identities
id (bigint, primary key)
user_id (bigint, foreign key)
provider (string) # steam, gog, facebook, google
uid (string) # Provider's user ID
access_token (text, encrypted)
refresh_token (text, encrypted)
expires_at (datetime)
steam_id (string) # For Steam specifically
profile_visibility (string) # public, private
created_at, updated_at

# Associations
belongs_to :user
```

**Important:** OAuth tokens are encrypted using Rails encrypted attributes. Never log or expose these.

### Games
```ruby
# Table: games
id (bigint, primary key)
title (string, required)
description (text)
platform (string) # steam, gog, epic, multi
external_id (string) # Platform-specific game ID
release_date (date)
genres (jsonb) # Array of genre strings
developer (string)
publisher (string)
igdb_id (integer)
igdb_data (jsonb) # Full IGDB response cached
created_at, updated_at

# Associations
has_many :user_games
has_many :users, through: :user_games

# Cache Strategy
# IGDB data is cached in igdb_data column
# Only refetch if >30 days old
```

### UserGames (The Backlog)
```ruby
# Table: user_games
id (bigint, primary key)
user_id (bigint, foreign key)
game_id (bigint, foreign key)
status (string) # backlog, playing, completed, abandoned
  # backlog = owned but not started
  # playing = currently playing
  # completed = finished
  # abandoned = started but gave up
priority (integer) # 1-10, nullable
hours_played (decimal) # Synced from Steam
rating (integer) # 1-5, nullable
notes (text)
last_synced_at (datetime)
created_at, updated_at

# Associations
belongs_to :user
belongs_to :game
```

### ChatSessions
```ruby
# Table: chat_sessions
id (bigint, primary key)
user_id (bigint, foreign key)
messages (jsonb) # Array of message objects
  # Example: [
  #   { role: "user", content: "What should I play?", timestamp: "..." },
  #   { role: "assistant", content: "Let me check...", timestamp: "..." }
  # ]
expires_at (datetime) # Defaults to 24 hours from creation
created_at, updated_at

# Associations
belongs_to :user

# Storage Strategy
# Session ID stored in Rails session cookie (~10 bytes)
# Messages stored in PostgreSQL JSONB (scalable, queryable)
# Sessions expire after 24 hours or browser close
```

---

## AI Chat System

### The 6 Custom Tools

Claude has access to 6 tools for managing the user's backlog:

#### 1. get_user_backlog
**Purpose:** Fetch user's game library with filtering
**Parameters:**
- `status` (optional): filter by backlog/playing/completed/abandoned
- `limit` (optional): max results, default 50

**Returns:** Array of games with status, hours_played, priority, rating
**Implementation:** `ToolExecutor#get_user_backlog` - ActiveRecord query on UserGames

**Example:**
```json
{
  "name": "get_user_backlog",
  "input": { "status": "playing", "limit": 10 }
}
```

#### 2. search_games
**Purpose:** Search IGDB for games by name
**Parameters:**
- `query` (required): search string
- `limit` (optional): max results, default 10

**Returns:** Array of games from IGDB
**Implementation:** Phase 2 - calls IGDB API, caches in Games table

#### 3. get_game_details
**Purpose:** Get full details for a specific game
**Parameters:**
- `game_id` (required): internal game ID OR
- `igdb_id` (required): IGDB game ID

**Returns:** Full game info including similar games, themes, storyline
**Implementation:** Phase 2 - check DB first, fetch from IGDB if missing

#### 4. add_to_backlog
**Purpose:** Add a game to user's backlog
**Parameters:**
- `game_id` or `igdb_id` (required)
- `status` (optional): defaults to 'backlog'
- `priority` (optional): 1-10

**Returns:** Confirmation with created UserGame
**Implementation:** Phase 2 - Create/update UserGame record

**Use cases:**
- Games found via IGDB search that aren't in Steam library
- Manual wishlist tracking
- GOG/Epic games (future)

#### 5. update_game_status
**Purpose:** Change status, rating, notes, priority
**Parameters:**
- `user_game_id` (required)
- `status`, `priority`, `rating`, `notes` (all optional)

**Returns:** Updated UserGame
**Implementation:** `ToolExecutor#update_game_status` - Simple update

#### 6. get_recommendations
**Purpose:** Analyze backlog and suggest what to play
**Parameters:**
- `context` (optional): "short session", "long RPG", etc.
- `limit` (optional): default 5

**Returns:** Array of recommended games with reasoning
**Implementation:** Phase 2 - Simple scoring algorithm:
- Query user's completed games (identify preferred genres)
- Query backlog games matching those patterns
- Score: genre match + priority + (negative for abandoned similar games)
- Return top matches with explanation

---

## Tech Stack

### Backend
- **Ruby** 3.2.3
- **Rails** 8.1.2
- **PostgreSQL** 13+ (primary database)
- **Solid Queue** (background jobs, built into Rails 8)
- **Solid Cache** (Rails cache, built into Rails 8)
- **Solid Cable** (WebSockets, built into Rails 8)

### Frontend
- **Hotwire** (Turbo + Stimulus)
- **Tailwind CSS** 4.x
- **Importmap** (no Node.js build step)
- **Propshaft** (asset pipeline)

### External APIs
- **Anthropic API** - Claude Sonnet 4.5 for chat
- **IGDB API** - Game metadata (Twitch API)
- **Steam Web API** - User library sync

### Authentication
- **OmniAuth** 2.1 with strategies:
  - omniauth-google-oauth2
  - omniauth-facebook
  - omniauth-steam (OpenID)
  - Custom GOG strategy (future)

### Testing
- **Minitest** (Rails default)
- **Capybara** + **Selenium** (system tests)
- **WebMock** (HTTP request stubbing)
- **Mocha** (mocking/stubbing)

### Code Quality
- **RuboCop** (rails-omakase config)
- **Brakeman** (security scanner)
- **Bundler-Audit** (dependency vulnerabilities)

### Deployment
- **Docker** + **Kamal** (planned)
- **Render** or **Fly.io** (initial target)
- **GitHub Actions** (CI/CD)

---

## Key Services & Components

### AnthropicService
**Location:** `app/services/anthropic_service.rb`

**Responsibilities:**
- Initialize Anthropic client with API key
- Build messages array from ChatSession
- Define tool schemas for all 6 tools
- Call Anthropic API with streaming
- Handle tool_use events by calling ToolExecutor
- Stream text chunks to frontend via SSE
- Save assistant messages to ChatSession

**Key Methods:**
```ruby
def send_message(&block)
  # Yields chunks: { type: "text", content: "..." }
  # or { type: "done" }
  # or { type: "error", content: "..." }
end

private

def tool_definitions
  # Returns array of 6 tool schemas
end

def build_messages
  # Converts ChatSession#messages to Anthropic format
end

def handle_response(response)
  # Routes to ToolExecutor or streams text
end
```

### ToolExecutor
**Location:** `app/services/tool_executor.rb`

**Responsibilities:**
- Execute tool calls from Claude
- Scope ALL queries to current_user (security critical)
- Return structured responses matching tool schemas
- Handle errors gracefully

**Key Methods:**
```ruby
def execute(tool_name, params)
  case tool_name
  when "get_user_backlog" then get_user_backlog(params)
  when "update_game_status" then update_game_status(params)
  # ... etc
  else
    raise UnknownToolError
  end
end

private

def get_user_backlog(params)
  # ALWAYS scope to @user
  scope = @user.user_games.includes(:game)
  # ... filtering, return array of hashes
end
```

**SECURITY NOTE:** Never trust tool parameters for user identification. Always use the @user instance variable set in initializer.

### SteamService (Future - Phase 3)
**Location:** `app/services/game_platforms/steam_service.rb`

**Responsibilities:**
- Fetch user's owned games from Steam API
- Fetch recent playtime
- Sync library to UserGames table
- Handle rate limits and errors

**API Endpoints:**
- `IPlayerService/GetOwnedGames/v1/` - Full library with playtime
- `IPlayerService/GetRecentlyPlayedGames/v1/` - Last 2 weeks

### SteamSyncJob (Future - Phase 3)
**Location:** `app/jobs/steam_sync_job.rb`

**Triggers:**
- Immediately after Steam OAuth connection
- Daily via scheduled job
- Manual "Sync Now" button

**Logic:**
```ruby
def perform(user_id)
  user = User.find(user_id)
  steam_service = GamePlatforms::SteamService.new(user.steam_identity)

  owned_games = steam_service.fetch_library

  owned_games.each do |steam_game|
    game = Game.find_or_create_from_steam(steam_game)
    user_game = user.user_games.find_or_initialize_by(game: game)

    user_game.hours_played = steam_game['playtime_forever'] / 60.0
    user_game.status ||= 'backlog'
    user_game.last_synced_at = Time.current
    user_game.save!
  end
end
```

---

## Implementation Phases

### Phase 1: Core Infrastructure (Current)
**Status:** In Development
**Branch:** `feature/phase1-anthropic-chat`
**Plan:** `docs/plans/2026-01-22-phase1-anthropic-chat.md`

**Tasks:**
- ✅ ChatSession model with JSONB message storage
- ⏳ ToolExecutor service framework (2/6 tools implemented)
- ⏳ AnthropicService with streaming SSE support
- ⏳ ChatController with session management
- ⏳ Stimulus-based chat UI
- ⏳ Integration tests

### Phase 2: Game Data & Tools (~1 week)
**Tasks:**
- Integrate IGDB API
- Implement remaining 4 chat tools
- Add Games and UserGames CRUD controllers
- Build basic library view with filters
- Test recommendation algorithm

### Phase 3: Steam Integration (~3-5 days)
**Tasks:**
- Implement SteamService class
- Build SteamSyncJob
- OAuth flow already done (Identity model exists)
- Test auto-sync on login

### Phase 4: UI Polish (~1 week)
**Tasks:**
- Build dashboard with stats widgets
- Add game detail pages with IGDB data
- Implement filters, search, sorting
- Mobile responsive design
- Loading states and error handling

### Phase 5: Deployment (~2-3 days)
**Tasks:**
- Set up Render/Fly.io account
- Configure production environment
- Deploy and smoke test
- Set up monitoring
- Configure scheduled jobs

### Phase 6: Refinements (Ongoing)
**Ideas:**
- Improve recommendation algorithm (ML, collaborative filtering)
- Add caching for IGDB and API responses
- GOG/Epic platform integration
- Persistent chat threads
- Social features (friends, sharing)
- Achievement tracking

---

## Environment Variables

### Required

```bash
# Rails
SECRET_KEY_BASE=...
RAILS_ENV=development

# Database (usually auto-set by platform)
DATABASE_URL=postgresql://localhost/backlog_manager_development

# Anthropic API (Phase 1)
ANTHROPIC_API_KEY=sk-ant-...

# Steam API (Phase 3)
STEAM_API_KEY=...
STEAM_OPENID_REALM=http://localhost:3000  # or https://yourapp.com

# OAuth (Already configured)
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
FACEBOOK_APP_ID=...
FACEBOOK_APP_SECRET=...
```

### Optional (Phase 2+)

```bash
# IGDB API (for game metadata)
IGDB_CLIENT_ID=...
IGDB_CLIENT_SECRET=...

# GOG (future)
GOG_CLIENT_ID=...
GOG_CLIENT_SECRET=...
```

### Storage

- **Development:** `.env` file (gitignored)
- **Production:** Platform environment variables (Render/Fly.io dashboard)
- **DO NOT** commit `.env` or `.mcp.json` to git

---

## Common Development Tasks

### Starting the App

```bash
# Install dependencies
bundle install

# Set up database
rails db:create
rails db:migrate

# Start server
rails server
# or
bin/dev  # if using Procfile

# Visit http://localhost:3000
```

### Running Tests

```bash
# All tests
rails test

# Specific test file
rails test test/models/user_test.rb

# Specific test
rails test test/models/user_test.rb:10

# System tests (requires Chrome)
rails test:system

# With coverage (if configured)
COVERAGE=true rails test
```

### Database Operations

```bash
# Create a migration
rails generate migration AddFieldToModel field:type

# Run pending migrations
rails db:migrate

# Rollback last migration
rails db:rollback

# Reset database (DESTRUCTIVE)
rails db:reset

# Open database console
rails dbconsole
# or
psql backlog_manager_development
```

### Code Quality

```bash
# Run RuboCop linter
bundle exec rubocop

# Auto-fix RuboCop issues
bundle exec rubocop -A

# Security scan
bundle exec brakeman

# Check for vulnerable dependencies
bundle exec bundler-audit

# Update dependencies
bundle update
```

### Generating Code

```bash
# Model
rails generate model Game title:string platform:string

# Controller
rails generate controller Games index show

# Migration
rails generate migration AddStatusToUserGames status:string

# Service (manual)
mkdir -p app/services
touch app/services/my_service.rb
```

### Rails Console

```bash
rails console

# Common commands
User.count
User.first
User.last
User.where(provider: 'steam')

# Create test data
user = User.create!(email: 'test@example.com', username: 'tester', provider: 'google', uid: '123')
```

---

## Testing Strategy

### Unit Tests (Models)
**Location:** `test/models/`

**What to test:**
- Validations
- Associations
- Scopes
- Instance methods
- Class methods

**Example:**
```ruby
# test/models/user_test.rb
test "should not save user without username" do
  user = User.new(email: 'test@example.com')
  assert_not user.save
end

test "has many user_games" do
  user = users(:one)
  assert_instance_of UserGame, user.user_games.first
end
```

### Integration Tests (Controllers)
**Location:** `test/controllers/`

**What to test:**
- HTTP responses (status codes, redirects)
- Flash messages
- Session changes
- Database changes

**Example:**
```ruby
# test/controllers/chat_controller_test.rb
test "creates new chat session on first message" do
  sign_in_as users(:one)

  assert_difference "ChatSession.count", 1 do
    post chat_message_url, params: { message: "Hello" }
  end

  assert_response :success
end
```

### System Tests
**Location:** `test/system/`

**What to test:**
- Full user workflows
- JavaScript interactions
- Multi-page flows

**Example:**
```ruby
# test/system/backlog_management_test.rb
test "user can add game to backlog" do
  visit root_url
  click_on "Sign in with Google"

  fill_in "Search", with: "Hollow Knight"
  click_on "Search"

  click_on "Add to Backlog"

  assert_text "Added to backlog"
end
```

### Test Fixtures
**Location:** `test/fixtures/`

Rails uses fixtures by default (not factories). Keep them simple and realistic.

```yaml
# test/fixtures/users.yml
one:
  email: user1@example.com
  username: testuser1
  provider: google_oauth2
  uid: "12345"

two:
  email: user2@example.com
  username: testuser2
  provider: steam
  uid: "76561198012345678"
```

### Mocking External APIs

Use WebMock to stub HTTP requests:

```ruby
# test/test_helper.rb
require 'webmock/minitest'
WebMock.disable_net_connect!(allow_localhost: true)

# In test file
stub_request(:post, "https://api.anthropic.com/v1/messages")
  .to_return(status: 200, body: {
    content: [{ type: "text", text: "Hello!" }]
  }.to_json)
```

---

## Security Considerations

### Authentication & Authorization
- ✅ Rails session cookies (encrypted, signed, httponly)
- ✅ CSRF protection enabled (Rails default)
- ✅ OAuth flows with state parameter validation
- ⚠️ ALL queries scoped to `current_user` (never trust params)

### Data Protection
- ✅ Encrypt OAuth tokens using Rails encrypted attributes
- ✅ HTTPS enforced in production (`config.force_ssl = true`)
- ✅ Filter sensitive params from logs
- ⚠️ Never expose API keys in frontend JavaScript
- ⚠️ Database indexes on `user_id` for performance

### Common Vulnerabilities to Avoid
- **SQL Injection:** Use ActiveRecord, never raw SQL with user input
- **XSS:** Rails auto-escapes ERB by default, keep it that way
- **CSRF:** Don't disable `protect_from_forgery`
- **Mass Assignment:** Use strong parameters in controllers
- **Secrets in Git:** `.env` and `.mcp.json` are gitignored

### OAuth Security
```ruby
# config/initializers/omniauth.rb
OmniAuth.config.on_failure = proc { |env|
  # Handle OAuth failures gracefully
}

# Always verify OAuth state parameter (Rails does this)
# Never skip CSRF protection for OAuth callbacks
```

---

## Error Handling

### Anthropic API
- **Rate limits (429):** Show "AI is busy, try again"
- **Timeouts:** 30s timeout, show "Request timed out"
- **Invalid tool calls:** Log error, return to Claude, let it retry
- **Network errors:** Disable chat, show "Chat temporarily unavailable"

### Steam API
- **Sync failures:** Log, display last successful sync time, allow retry
- **Auth expired (401):** Prompt user to reconnect Steam
- **Rate limits:** Respect 100k calls/day, queue syncs if needed

### IGDB API
- **Search failures:** Return empty results with error message
- **Network errors:** Fall back to cached data if available
- **Cache aggressively:** Store in DB, refetch only if >30 days old

### Frontend
- Toast notifications for non-critical errors
- Inline validation errors on forms
- Loading states for all async actions
- Graceful chat degradation

---

## Deployment

### Target Platforms
- **Render** (recommended for hobby tier)
- **Fly.io** (alternative)
- **Heroku** (more expensive)

### Services Needed
- Web server: Rails app (1 dyno/instance)
- Database: Managed PostgreSQL (free tier OK for start)
- Background jobs: Solid Queue (no separate service needed!)
- File storage: Not needed (no user uploads)

### Environment Setup
1. Create account on Render/Fly.io
2. Connect GitHub repo
3. Set environment variables in dashboard
4. Configure build command: `bundle install && rails assets:precompile`
5. Configure start command: `bundle exec puma -C config/puma.rb`

### Database Migrations
```bash
# Automatic on deploy (configure in Render/Fly.io)
bundle exec rails db:migrate
```

### Cost Estimate (Hobby Tier)
- Hosting: $5-7/month (or free tier)
- Anthropic API: ~$5/month (personal use, pay-as-you-go)
- Steam API: Free
- IGDB API: Free
- **Total: ~$10-15/month**

---

## Coding Standards

### Ruby/Rails
- Follow **rails-omakase** RuboCop configuration (already configured)
- Use service objects for complex business logic (`app/services/`)
- Prefer `has_many :through` over `has_and_belongs_to_many`
- Use strong parameters in controllers
- Keep controllers thin, models focused (business logic in services)

### JavaScript/Stimulus
- One controller per behavior
- Use data attributes for configuration
- Prefer Turbo over custom JS where possible
- Name targets descriptively: `data-controller-target="messageList"`

### Testing
- Every model needs unit tests (validations, associations)
- Every controller action needs request tests
- Complex flows need system tests
- Use fixtures (Rails default), not factories
- Aim for >80% coverage

### Git
- Branch format: `feature/short-description` or `fix/issue-description`
- Commit messages: imperative mood, 50 char subject, body explains why
- Always run tests before pushing
- Never commit `.env` or `.mcp.json`

---

## Key Design Decisions

### Why Anthropic API over Bedrock?
- Native MCP support (for future if needed)
- Simpler integration and better documentation
- Cheaper for hobby/small scale
- Can migrate to Bedrock later if AWS integration becomes valuable

### Why Tool Use over MCP Servers?
- Simpler architecture - everything in Rails
- No separate hosting costs or complexity
- Anthropic API MCP support requires HTTP-accessible servers
- Can refactor to MCP later if standardization is needed

### Why Session-Based Chat over Persistent Threads?
- Simpler for v1 - no complex thread management UI
- Most user interactions are contextual ("what should I play now?")
- Can upgrade to persistent threads in Phase 6
- Reduces DB storage in early stages

### Why Solid Queue over Sidekiq/Redis?
- Built into Rails 8
- One less service to host and maintain
- Sufficient for hobby-scale background jobs
- Easy to upgrade to Redis-backed queue later

### Why Simple Scoring over ML Recommendations?
- Faster to build and iterate
- Transparent and debuggable
- Good enough for v1 validation
- ML/collaborative filtering can be added incrementally

---

## Troubleshooting

### "Can't connect to PostgreSQL"
```bash
# Check if PostgreSQL is running
brew services list  # macOS
sudo service postgresql status  # Linux

# Start PostgreSQL
brew services start postgresql  # macOS
sudo service postgresql start  # Linux

# Check database.yml configuration
cat config/database.yml
```

### "Anthropic API error"
```bash
# Check API key is set
echo $ANTHROPIC_API_KEY

# Verify in .env file
grep ANTHROPIC .env

# Test API key manually
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```

### "Test failures after pulling latest"
```bash
# Ensure database is up to date
rails db:migrate RAILS_ENV=test

# Reset test database
rails db:test:prepare

# Re-run tests
rails test
```

### "OAuth callback fails locally"
```bash
# Check callback URL matches in OAuth provider dashboard
# For Google: http://localhost:3000/auth/google_oauth2/callback
# For Steam: http://localhost:3000/auth/steam/callback

# Verify OmniAuth initializer
cat config/initializers/omniauth.rb

# Check environment variables
grep -E "(GOOGLE|FACEBOOK|STEAM)" .env
```

---

## Quick Reference

| Task | Command |
|------|---------|
| Start server | `rails server` or `bin/dev` |
| Run all tests | `rails test` |
| Run system tests | `rails test:system` |
| Lint code | `bundle exec rubocop` |
| Fix lint issues | `bundle exec rubocop -A` |
| Security scan | `bundle exec brakeman` |
| Audit dependencies | `bundle exec bundler-audit` |
| Database console | `rails dbconsole` |
| Rails console | `rails console` |
| Create migration | `rails g migration AddX field:type` |
| Rollback migration | `rails db:rollback` |
| View routes | `rails routes` |
| View routes for games | `rails routes | grep game` |

---

## Additional Resources

### Documentation
- **Design Doc:** `docs/plans/2026-01-22-ai-backlog-manager-design.md`
- **Phase 1 Plan:** `docs/plans/2026-01-22-phase1-anthropic-chat.md`
- **Anthropic Integration:** `docs/ANTHROPIC_INTEGRATION.md` (after Phase 1)

### External Docs
- [Rails Guides](https://guides.rubyonrails.org/)
- [Anthropic API Docs](https://docs.anthropic.com/)
- [IGDB API Docs](https://api-docs.igdb.com/)
- [Steam Web API Docs](https://steamcommunity.com/dev)
- [Hotwire Docs](https://hotwired.dev/)

### Repository
- **GitHub:** https://github.com/dodontommy/backlog-manager
- **Issues:** https://github.com/dodontommy/backlog-manager/issues

---

## Notes for Future Agents

1. **Always check the phase status** at the top of this document to know where we are
2. **Read the design doc** before making major changes
3. **Run tests** before committing - we maintain a clean test suite
4. **Security is critical** - this app handles OAuth tokens and user data
5. **Keep it simple** - resist over-engineering, YAGNI principle
6. **Chat sessions expire** - don't rely on long-term chat memory yet
7. **API keys rotate** - if MCP or tests fail, check `.mcp.json` keys
8. **Git worktrees are used** for isolation - check `.worktrees/` for active work

**When in doubt, ask the user!**
