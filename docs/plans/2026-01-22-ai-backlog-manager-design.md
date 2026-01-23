# AI Gaming Backlog Manager - Design Document

**Date:** 2026-01-22
**Status:** Approved
**Target:** Hobby/personal project, scaling path available

## Overview

A web-based gaming backlog manager that uses AI to help users decide what to play next. The app syncs with Steam (and eventually other platforms), tracks game status and progress, and provides intelligent recommendations through a conversational AI interface.

## Core Problem

Gamers accumulate large libraries across multiple platforms but struggle to decide what to play. Existing backlog trackers are just lists - this app uses AI to analyze playing patterns and preferences to make personalized recommendations.

## Architecture

### System Components

1. **Rails Web Application** - Handles routing, auth, database, UI, API orchestration
2. **Anthropic API** - Claude with custom tool definitions for game management
3. **External APIs** - IGDB (game metadata), Steam Web API (library sync)
4. **PostgreSQL Database** - User accounts, backlog data, chat sessions
5. **Frontend** - Tailwind CSS, Hotwire/Turbo, streaming chat interface

### Request Flow

```
User sends chat message
    ↓
Rails receives message, calls Anthropic API with:
  - Conversation history from ChatSession
  - Tool definitions (6 custom tools)
    ↓
Claude responds with either:
  - Text response → Stream to user
  - Tool call request → Rails executes tool
    ↓
If tool call:
  Rails calls IGDB or Steam API directly
    ↓
  Sends result back to Anthropic
    ↓
  Claude processes tool result and responds
    ↓
Stream final response to user
```

### Why Not MCP Servers?

Initial consideration was to use MCP servers for IGDB/Steam integration. However:
- MCP servers via Anthropic API require hosting them as separate HTTP/SSE endpoints
- For a hobby project, this adds unnecessary complexity and hosting costs
- Using Anthropic's standard tool use feature keeps everything in Rails
- Can migrate to MCP later if needed for standardization or reuse

## Data Model

### Users
- `id`, `email`, `username`, `created_at`, `updated_at`
- `last_steam_sync_at` (datetime)
- **Associations:** `has_many :identities`, `has_many :user_games`, `has_many :chat_sessions`

### Identities (OAuth connections)
- `id`, `user_id`, `provider` (steam, gog, facebook, google)
- `uid` (provider's user ID)
- `access_token` (encrypted), `refresh_token` (encrypted), `expires_at`
- `steam_id` (string, for Steam specifically)
- **Associations:** `belongs_to :user`

### Games
- `id`, `title`, `description`, `platform`, `external_id`
- `release_date`, `genres` (jsonb array), `developer`, `publisher`
- `igdb_id` (integer), `igdb_data` (jsonb - cached IGDB response)
- `created_at`, `updated_at`
- **Associations:** `has_many :user_games`
- **Cache strategy:** Store full IGDB responses, refresh only if >30 days old

### UserGames (the backlog)
- `id`, `user_id`, `game_id`
- `status` (enum: backlog, playing, completed, abandoned)
  - `backlog` = owned but not started
  - `playing` = currently playing
  - `completed` = finished
  - `abandoned` = started but gave up
- `priority` (integer 1-10, nullable)
- `hours_played` (decimal, synced from Steam)
- `rating` (integer 1-5, nullable)
- `notes` (text)
- `last_synced_at`, `created_at`, `updated_at`
- **Associations:** `belongs_to :user`, `belongs_to :game`

### ChatSessions
- `id`, `user_id`
- `messages` (jsonb array) - stores full conversation history
- `created_at`, `updated_at`, `expires_at`
- **Storage:** Session ID stored in Rails session cookie (tiny), messages stored in DB
- **Associations:** `belongs_to :user`

## AI Chat Tools

Six custom tools defined for Claude to manage user's backlog:

### 1. `get_user_backlog`
**Purpose:** Fetch user's game library with filtering
**Parameters:**
- `status` (optional): filter by backlog/playing/completed/abandoned
- `limit` (optional): max results, default 50

**Returns:** Array of games with status, hours_played, priority, rating
**Implementation:** ActiveRecord query on UserGames scoped to current_user

### 2. `search_games`
**Purpose:** Search IGDB for games by name
**Parameters:**
- `query` (required): search string
- `limit` (optional): max results, default 10

**Returns:** Array of games from IGDB (title, genres, rating, platforms)
**Implementation:** Call IGDB API, cache results in Games table

### 3. `get_game_details`
**Purpose:** Get full details for a specific game
**Parameters:**
- `game_id` (required): internal game ID OR
- `igdb_id` (required): IGDB game ID

**Returns:** Full game info including similar games, themes, storyline
**Implementation:** Check DB first, fetch from IGDB if missing, cache for 30 days

### 4. `add_to_backlog`
**Purpose:** Add a game to user's backlog
**Parameters:**
- `game_id` or `igdb_id` (required)
- `status` (optional): defaults to 'backlog'
- `priority` (optional)

**Returns:** Confirmation with created UserGame
**Implementation:** Create/update UserGame record, create Game from IGDB if needed
**Use cases:**
- Games found via IGDB search that aren't in Steam library
- Manual wishlist tracking
- GOG/Epic games (future)

### 5. `update_game_status`
**Purpose:** Change status, rating, notes, priority
**Parameters:**
- `user_game_id` (required)
- `status`, `priority`, `rating`, `notes` (all optional)

**Returns:** Updated UserGame
**Implementation:** Simple update on UserGame record

### 6. `get_recommendations`
**Purpose:** Analyze backlog and suggest what to play
**Parameters:**
- `context` (optional): "short session", "long RPG", etc.
- `limit` (optional): default 5

**Returns:** Array of recommended games with reasoning
**Implementation (v1 - simple scoring):**
- Query user's completed games (identify preferred genres/patterns)
- Query backlog games matching those patterns
- Score based on: genre match weight + priority + (negative weight for abandoned similar games)
- Return top matches with explanation
- **Future:** More sophisticated ML/collaborative filtering

## Chat Interface Implementation

### Backend

**ChatController** (`POST /chat/message`)
```ruby
def create
  # Get or create session (ID stored in cookie)
  session_id = session[:chat_session_id] ||= create_chat_session
  chat_session = current_user.chat_sessions.find(session_id)

  # Add user message to DB
  user_message = params[:message]
  chat_session.add_message(role: 'user', content: user_message)

  # Stream response via SSE
  response.headers['Content-Type'] = 'text/event-stream'

  anthropic_service = AnthropicService.new(current_user, chat_session)
  anthropic_service.send_message(user_message) do |chunk|
    response.stream.write("data: #{chunk.to_json}\n\n")
  end
ensure
  response.stream.close
end
```

**AnthropicService**
- Builds messages array from ChatSession
- Defines tool schemas for all 6 tools
- Calls Anthropic API with streaming enabled
- On tool_use events: executes tool via ToolExecutor, sends result back to Anthropic
- On content_block_delta events: streams text chunks to frontend
- Handles multi-turn tool calls transparently

**ToolExecutor**
- Routes tool calls to appropriate service methods
- Scopes all queries to current_user for security
- Returns structured responses matching tool schemas

### Frontend

**Stimulus controller** (`chat_controller.js`)
- Handles form submission
- Streams SSE responses from backend
- Appends messages to chat UI in real-time
- Shows typing indicators during streaming

**UI Components:**
- Collapsible sidebar on desktop
- Modal/overlay on mobile
- Quick prompt buttons ("What should I play?", "Show my RPGs")
- Message history preserved during session

### Session Management

**Browser session (temporary):**
- Chat session ID stored in Rails session cookie (~10 bytes)
- Messages stored in ChatSessions table (jsonb)
- Expires after user closes browser or 24 hours
- **Future (Phase 6):** Persistent threads with multiple conversations

## Steam Library Sync

### SteamService

**Methods:**
- `fetch_library` - Calls Steam GetOwnedGames API
- `fetch_recent_games` - Calls Steam GetRecentlyPlayedGames API (for detecting active games)

**API endpoints used:**
- `IPlayerService/GetOwnedGames/v1/` - Full library with playtime
- `IPlayerService/GetRecentlyPlayedGames/v1/` - Last 2 weeks activity

### SteamSyncJob (Background Job)

**Runs:**
- Immediately after Steam OAuth connection
- Daily via scheduled job (Solid Queue)
- Manually via "Sync Now" button in settings

**Logic:**
```ruby
owned_games = steam_service.fetch_library

owned_games.each do |steam_game|
  game = Game.find_or_create_from_steam(steam_game)
  user_game = user.user_games.find_or_initialize_by(game: game)

  # Update playtime
  user_game.hours_played = steam_game['playtime_forever'] / 60.0
  user_game.last_synced_at = Time.current

  # Set initial status if new
  user_game.status ||= 'backlog'

  user_game.save!
end
```

**Smart sync features:**
- Preserve user manual changes (priority, rating, notes, status overrides)
- If playtime increased significantly → suggest status change to 'playing'
- If no playtime in 30 days and status='playing' → suggest moving to backlog/completed
- **Future:** Achievement tracking for auto-completion detection

### OAuth Flow

1. User clicks "Connect Steam"
2. Redirects to Steam OpenID
3. Callback receives Steam ID
4. Create/update Identity record
5. Trigger immediate SteamSyncJob
6. Redirect to library view with success message

## UI Pages

### 1. Dashboard (`/dashboard`)
- Quick stats widget (total games, hours played, completion rate, currently playing count)
- "Currently Playing" section (games with status='playing', sorted by recent activity)
- Top 3 AI recommendations with brief reasoning
- Recent activity feed (syncs, completions)
- Chat interface in sidebar

### 2. Library (`/games`)
- Table/grid view of all UserGames
- Filters: Status dropdown, platform badges, title search
- Sort options: Title, hours played, priority, date added
- Game cards show: Cover art, title, platform, hours, status badge, priority stars, rating
- Quick actions: Status dropdown, priority slider, delete
- Pagination (25 per page)

### 3. Game Detail (`/games/:id`)
- Hero section: Cover art, title, release date
- Game info from IGDB: Description, genres, developer, publisher, platforms
- User tracking panel:
  - Status selector (backlog/playing/completed/abandoned)
  - Priority slider (1-10)
  - Rating stars (1-5)
  - Notes textarea
- Stats: Hours played, playtime trend (future)
- Similar games carousel (from IGDB)

### 4. Settings (`/settings`)
- Connected accounts section:
  - Steam: Connection status, last synced, "Sync Now" button, disconnect option
  - GOG: Coming soon
  - Epic: Coming soon
- Preferences (future):
  - Chat history retention
  - Email notifications
  - Sync frequency

### 5. Chat Interface (Embedded Everywhere)
- Sticky sidebar (desktop) or floating button → modal (mobile)
- Quick prompts:
  - "What should I play tonight?"
  - "Show me my backlog RPGs"
  - "Recommend something under 10 hours"
- Message history scrolls, auto-scrolls to bottom on new messages

## Error Handling

### Anthropic API
- **Rate limits (429):** Show "AI is busy, please try again in a moment"
- **Timeouts:** 30s timeout, display "Request took too long, please try again"
- **Invalid tool calls:** Log error, return error message to Claude, let it retry
- **Network errors:** Graceful degradation - disable chat, show "Chat temporarily unavailable"

### Steam API
- **Sync failures:** Log to system, display last successful sync time, allow manual retry
- **Auth expired (401):** Detect and prompt user to reconnect Steam account
- **Rate limits:** Respect Steam's 100k calls/day limit, queue syncs if needed

### IGDB API
- **Search failures:** Return empty results with inline error message
- **Network errors:** Fall back to cached data if available
- **Cache aggressively:** Store IGDB responses in DB, only refetch if stale (>30 days)

### Frontend
- Toast notifications for non-critical errors
- Inline validation errors on forms
- Loading states for all async actions
- Graceful chat degradation (disable input, show banner)

## Security

### Authentication & Authorization
- Rails session cookies (encrypted, signed, httponly)
- CSRF protection enabled (Rails default)
- OAuth flows with state parameter validation
- All queries scoped to `current_user` (never trust user_id from params)

### Data Protection
- Encrypt OAuth tokens using Rails encrypted attributes (`encrypts :access_token, :refresh_token`)
- HTTPS enforced in production (`config.force_ssl = true`)
- Filter sensitive params from logs (tokens, passwords)
- Database indexes on `user_id` for performance and to prevent enumeration

### API Keys
- Never expose in frontend JavaScript
- Store in environment variables only
- .env file gitignored
- Rotate immediately if compromised

### Rate Limiting (Future - Phase 6)
- Rack::Attack for endpoint protection
- Limit chat messages to 20/minute per user
- Limit manual sync to 1/hour per user
- Limit failed login attempts

## Deployment & Hosting

### Local Development
- Rails server on localhost:3000
- PostgreSQL running locally
- `.env` file for secrets (gitignored)
- Solid Queue for background jobs (in-process, no Redis needed)

### Production Hosting (Render/Fly.io/Heroku)

**Services:**
- Web server: Rails app (free tier or $7/month)
- Database: Managed Postgres (free tier for hobby)
- Background jobs: Solid Queue (built into Rails 8)
- File storage: Not needed (no user uploads)

**Environment variables:**
```bash
SECRET_KEY_BASE=...
RAILS_ENV=production
DATABASE_URL=postgresql://...
STEAM_API_KEY=...
ANTHROPIC_API_KEY=...
STEAM_OPENID_REALM=https://yourapp.com
GOG_CLIENT_ID=...
GOG_CLIENT_SECRET=...
```

**Deployment steps:**
1. Set up platform account (Render/Fly.io)
2. Configure environment variables
3. Update OAuth redirect URLs for production domain
4. Run migrations on production DB
5. Deploy via git push
6. Schedule daily Steam sync job
7. Set up error monitoring (Sentry/Honeybadger free tier)

**Cost estimate:**
- Hosting: $5-7/month (or free tier)
- Anthropic API: Pay-as-you-go (~$5/month for personal use)
- Steam API: Free
- IGDB API: Free
- **Total: ~$10-15/month**

### Backups
- Platform automated daily backups
- Manual export before schema changes
- Chat sessions can be purged periodically (low value after 30 days)

### Scaling Path (If Needed Later)
- Add Redis for caching and better job queue performance
- Upgrade Postgres tier for more connections/storage
- Add CDN for static assets (Cloudflare free tier)
- Horizontal scaling with more web dynos
- Database read replicas if needed

## Implementation Phases

### Phase 1: Core Infrastructure (~1 week)
- Set up Anthropic API integration with streaming
- Implement tool definitions and ToolExecutor
- Create ChatSessions model and controller
- Build basic chat UI with Stimulus
- Test tool execution flow end-to-end

### Phase 2: Game Data & Tools (~1 week)
- Integrate IGDB API
- Implement all 6 chat tools
- Add Games and UserGames CRUD controllers
- Build basic library view with filters
- Test recommendation algorithm

### Phase 3: Steam Integration (~3-5 days)
- Implement SteamService class
- Build SteamSyncJob
- Add "Connect Steam" OAuth flow
- Test auto-sync on login
- Handle token refresh and errors

### Phase 4: UI Polish (~1 week)
- Build dashboard with stats widgets
- Add game detail pages with IGDB data
- Implement filters, search, sorting
- Mobile responsive design
- Loading states and error handling

### Phase 5: Deployment (~2-3 days)
- Set up Render/Fly.io account
- Configure production environment
- Deploy and smoke test
- Set up monitoring and logging
- Configure scheduled jobs

### Phase 6: Refinements (Ongoing)
- Improve recommendation algorithm (ML, collaborative filtering)
- Add caching for IGDB and API responses
- GOG/Epic platform integration
- Persistent chat threads
- Social features (friends, sharing)
- Achievement tracking
- Advanced analytics

## Testing Strategy

### Unit Tests
- Models: Validations, associations, scopes
- Services: SteamService, AnthropicService, ToolExecutor
- Jobs: SteamSyncJob logic

### Integration Tests
- Tool execution: All 6 tools return correct data
- ChatController: Message handling and streaming
- OAuth flows: Steam connection and callback

### System Tests
- Full chat conversation flow
- Steam sync populates library
- Game status updates reflect in UI
- Recommendations appear in dashboard

### Manual Testing
- OAuth flows in production
- Streaming chat performance
- Mobile responsive design
- Error handling edge cases

## Future Enhancements (Post-Launch)

### Platform Expansion
- GOG Galaxy integration
- Epic Games Store integration
- PlayStation Network integration
- Xbox Live integration
- Nintendo Switch integration

### AI Improvements
- Collaborative filtering (recommend based on users with similar tastes)
- Time-aware suggestions (match game length to available time)
- Mood/context awareness (action vs relaxing, multiplayer vs solo)
- Learning from user feedback (thumbs up/down on recommendations)

### Social Features
- Share backlog with friends
- See what friends are playing
- Compare completion rates
- Recommendations based on friend activity

### Advanced Tracking
- Achievement tracking and completion percentage
- Playtime trends and analytics
- Genre/developer preference analysis
- Spending tracker (integrate with purchase history)

### Quality of Life
- Browser extension to add games from store pages
- Mobile app (React Native or PWA)
- Email digests ("Your weekly recommendations")
- Webhooks for Discord/Slack notifications
- Export backlog to CSV/JSON

## Key Technical Decisions

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

## Success Metrics (Post-Launch)

- **User engagement:** Daily active users, chat messages per session
- **Sync health:** Steam sync success rate, API error rates
- **Recommendation quality:** Click-through rate on suggestions, status changes to "playing"
- **Completion tracking:** Games marked completed over time
- **Performance:** Chat response time, page load times
- **Cost efficiency:** Anthropic API spend per user

## Risks & Mitigations

### Risk: Anthropic API costs spike
**Mitigation:** Set up billing alerts, implement rate limiting, cache common responses

### Risk: Steam API rate limits
**Mitigation:** Queue syncs, respect rate limits, cache aggressively

### Risk: Chat streaming doesn't work on all browsers
**Mitigation:** Fallback to polling for older browsers, test on major browsers

### Risk: Recommendation quality is poor
**Mitigation:** Start simple, gather user feedback, iterate on algorithm

### Risk: OAuth integrations break
**Mitigation:** Monitor error rates, handle token refresh properly, log failures

## Conclusion

This design provides a clear path from hobby project to production-ready application. The architecture is simple enough to build quickly but flexible enough to scale and add features over time. By starting with Anthropic's tool use feature and Steam-only integration, we minimize complexity while delivering core value: helping users decide what to play next through AI-powered recommendations.
