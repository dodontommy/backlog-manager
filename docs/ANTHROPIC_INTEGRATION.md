# Anthropic Integration

## Overview

The chat interface integrates with Anthropic's Claude API to provide AI-powered backlog management through a conversational interface with real-time streaming responses.

## Architecture

### Components

1. **ChatSession** - Stores conversation history in PostgreSQL with JSONB
2. **AnthropicService** - Handles API calls, streaming, and tool execution
3. **ToolExecutor** - Executes tool calls requested by Claude
4. **ChatController** - Manages HTTP/SSE streaming to frontend
5. **Stimulus Controller** - Handles frontend streaming and UI updates

### Request Flow

```
User Message
    ↓
Frontend (Stimulus)
    ↓
ChatController (SSE streaming)
    ↓
AnthropicService
    ↓
Anthropic API (Claude Sonnet 4.5)
    ├─→ Text Response → Stream to user
    └─→ Tool Call → ToolExecutor → Database → Continue conversation
```

### Streaming Architecture

**Server-Sent Events (SSE):**
- Controller sets `Content-Type: text/event-stream`
- Chunks sent as `data: {json}\n\n`
- Frontend reads stream incrementally
- Response appears in real-time (character-by-character)

**Non-Streaming (Tests):**
- When no block given to `send_message`
- Returns complete response as string
- Used in test environment

## Tools Available

### 1. get_user_backlog
**Purpose:** Fetch user's games with filtering
**Status:** ✅ Implemented
**Parameters:**
- `status` (optional): filter by backlog/playing/completed/abandoned
- `limit` (optional): max results, default 50

**Returns:** Array of games with status, hours_played, priority, rating

**Implementation:** `ToolExecutor#get_user_backlog` - ActiveRecord query on UserGames

### 2. update_game_status
**Purpose:** Update game status, priority, rating, or notes
**Status:** ✅ Implemented
**Parameters:**
- `user_game_id` (required): ID of UserGame record
- `status`, `priority`, `rating`, `notes` (all optional)

**Returns:** Updated UserGame with success flag

**Security:** Scoped to `@user` - cannot update other users' games

### 3. search_games
**Purpose:** Search IGDB for games by name
**Status:** ⏳ Phase 2
**Implementation:** Will call IGDB API, cache in Games table

### 4. get_game_details
**Purpose:** Get full details for a specific game
**Status:** ⏳ Phase 2
**Implementation:** Check DB first, fetch from IGDB if missing

### 5. add_to_backlog
**Purpose:** Add a game to user's backlog
**Status:** ⏳ Phase 2
**Use cases:** Manual wishlist tracking, GOG/Epic games

### 6. get_recommendations
**Purpose:** AI-powered game recommendations
**Status:** ⏳ Phase 2
**Implementation:** Scoring algorithm based on completed games and preferences

## Configuration

### Environment Variables

Required:
```bash
ANTHROPIC_API_KEY=sk-ant-...
```

Set in `.env` for development, platform environment variables for production.

### Model Configuration

**Model:** `claude-sonnet-4-5-20250929`
**Max Tokens:** 4096
**Timeout:** 60 seconds
**Tool Depth Limit:** 5 (prevents infinite recursion)

## Testing

### Unit Tests
- **Models:** `test/models/chat_session_test.rb`
- **Services:** `test/services/tool_executor_test.rb`, `test/services/anthropic_service_test.rb`
- **Controllers:** `test/controllers/chat_controller_test.rb`

### Integration Tests
- **Chat Flow:** `test/integration/chat_flow_test.rb`

### Test Strategy

Tool execution is stubbed using Mocha:

```ruby
@mock_service = mock("anthropic_service")
@mock_service.stubs(:send_message).with do |message, &block|
  if block_given?
    block.call({ type: "text", content: "Response" })
    block.call({ type: "done" })
  end
  true
end
AnthropicService.stubs(:new).returns(@mock_service)
```

**Why mock?**
- Avoid actual API calls in tests (cost, speed, reliability)
- Tests run without network connection
- Consistent test behavior

## Error Handling

### Anthropic API Errors

| Error | Handling |
|-------|----------|
| Rate limits (429) | Logged, error message to user via SSE |
| Timeouts | 60s timeout, error chunk sent to frontend |
| Invalid tool calls | Logged, error returned to Claude for retry |
| Network errors | Caught in rescue, error sent via SSE |

### Tool Execution Errors

| Error | Handling |
|-------|----------|
| Unknown tool | Raises `ToolExecutor::UnknownToolError` |
| Missing parameters | Returns `{ success: false, error: "..." }` |
| Database errors | Caught, logged, error returned to Claude |
| Authorization | All queries scoped to `@user` - prevents cross-user access |

### Frontend Errors

- SSE disconnection handled gracefully
- Error chunks displayed inline in chat
- Input re-enabled after error
- User can retry immediately

## Security Considerations

### Critical Security Rules

1. **NEVER trust tool parameters for user identification**
   ```ruby
   # ❌ WRONG - user_id from params can be forged
   def get_user_backlog(params)
     User.find(params["user_id"]).user_games
   end

   # ✅ CORRECT - always use @user from initializer
   def get_user_backlog(params)
     @user.user_games.where(...)
   end
   ```

2. **All database queries scoped to current user**
   ```ruby
   @user.user_games.find(params["user_game_id"])  # ✅ Safe
   UserGame.find(params["user_game_id"])          # ❌ Unsafe
   ```

3. **API key never exposed to frontend**
   - Stored in ENV
   - Only accessed server-side in AnthropicService
   - Not logged or sent in responses

4. **Session security**
   - Rails encrypted session cookies
   - CSRF protection enabled
   - Sessions expire after 24 hours

## Performance Considerations

### Database
- Indexes on `chat_sessions.user_id` and `chat_sessions.expires_at`
- JSONB for efficient message storage
- `includes(:game)` to avoid N+1 queries in `get_user_backlog`

### Streaming
- Chunks sent immediately as received from Anthropic
- No server-side buffering
- Low memory footprint

### API Costs
- Claude Sonnet 4.5 pricing: ~$3 per million input tokens
- Typical conversation: 1000-5000 tokens
- Estimated cost: ~$0.01-0.05 per conversation
- Tools add minimal overhead (JSON schemas)

## Future Enhancements

### Phase 2
- Implement remaining 4 tools (IGDB integration)
- Add tool call visualization in UI
- Cache IGDB responses

### Phase 6+
- Persistent chat threads (beyond 24-hour sessions)
- Conversation branching
- Export chat history
- Multi-turn context optimization
- Streaming tool results (show "Searching IGDB..." in real-time)

## Troubleshooting

### "Anthropic API error"
```bash
# Check API key
echo $ANTHROPIC_API_KEY

# Test manually
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model":"claude-sonnet-4-5-20250929","max_tokens":10,"messages":[{"role":"user","content":"hi"}]}'
```

### "Streaming doesn't work"
- Check browser console for JavaScript errors
- Verify `Content-Type: text/event-stream` header
- Ensure no proxies buffering SSE
- Test with `curl -N` to see raw SSE stream

### "Tool calls fail"
- Check `@user` is set correctly in ToolExecutor
- Verify tool name matches definition exactly
- Check logs for parameter validation errors
- Ensure user has data in database (user_games, etc.)

## Development Workflow

### Adding a New Tool

1. **Define tool schema** in `AnthropicService#tool_definitions`
2. **Implement handler** in `ToolExecutor`
3. **Write tests** in `test/services/tool_executor_test.rb`
4. **Update documentation** (this file)
5. **Test manually** via chat interface

### Testing Chat Locally

```bash
rails server
# Visit http://localhost:3000
# Sign in via OAuth
# Open browser console to see streaming events
# Type: "Show me my backlog"
```

## API Reference

### AnthropicService

```ruby
service = AnthropicService.new(user, chat_session)

# Streaming mode (production)
service.send_message("What should I play?") do |chunk|
  # chunk = { type: "text", content: "..." }
  # or { type: "done" }
  # or { type: "error", content: "..." }
end

# Non-streaming mode (tests)
response = service.send_message("What should I play?")
# => "Based on your backlog..."
```

### ToolExecutor

```ruby
executor = ToolExecutor.new(current_user)

result = executor.execute("get_user_backlog", { "status" => "playing" })
# => { games: [...] }

result = executor.execute("update_game_status", {
  "user_game_id" => 123,
  "status" => "completed",
  "rating" => 5
})
# => { success: true, id: 123, status: "completed", ... }
```

## Resources

- [Anthropic API Docs](https://docs.anthropic.com/)
- [Tool Use Guide](https://docs.anthropic.com/en/docs/tool-use)
- [SSE Specification](https://html.spec.whatwg.org/multipage/server-sent-events.html)
- [Rails Streaming Guide](https://guides.rubyonrails.org/api_app.html#streaming)
