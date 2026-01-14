# API Integrations Guide

This document provides detailed information about all external API integrations used in What The Game.

---

## 🎮 Gaming Platform APIs

### Steam Web API

**Purpose**: Access user's Steam library, game details, playtime, achievements

**Documentation**: https://developer.valvesoftware.com/wiki/Steam_Web_API

**Authentication**: API Key (no OAuth required)

**Setup**:
1. Visit https://steamcommunity.com/dev/apikey
2. Sign in with Steam account
3. Register for API key (use your domain or `localhost` for dev)
4. Add to `.env`: `STEAM_API_KEY=your_key`

**Key Endpoints**:
```ruby
# Get owned games
GET http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/
  ?key={API_KEY}
  &steamid={STEAM_ID}
  &include_appinfo=true
  &include_played_free_games=true

# Get player summaries
GET http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/
  ?key={API_KEY}
  &steamids={STEAM_ID}

# Get user achievements for game
GET http://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/
  ?appid={APP_ID}
  &key={API_KEY}
  &steamid={STEAM_ID}

# Get game details
GET http://store.steampowered.com/api/appdetails
  ?appids={APP_ID}

# Get recently played games
GET http://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/
  ?key={API_KEY}
  &steamid={STEAM_ID}
```

**Rate Limits**: 
- ~200 requests per 5 minutes per API key
- Be conservative, implement exponential backoff

**Notes**:
- Steam ID can be obtained from profile URL or vanity URL resolver
- Some endpoints require user's profile to be public
- Game data from store API is not rate limited but less reliable

**Implementation Priority**: ⭐⭐⭐⭐⭐ (Phase 1, Critical)

---

### GOG (Good Old Games) API

**Purpose**: Access GOG library, game details, playtime

**Documentation**: https://gogapidocs.readthedocs.io/ (unofficial)

**Authentication**: OAuth 2.0

**Setup**:
1. Register at GOG Developer Portal (application required)
2. Create application, get client credentials
3. Add to `.env`: `GOG_CLIENT_ID` and `GOG_CLIENT_SECRET`

**OAuth Flow**:
```ruby
# Authorization URL
https://auth.gog.com/auth
  ?client_id={CLIENT_ID}
  &redirect_uri={REDIRECT_URI}
  &response_type=code
  &scope=

# Token exchange
POST https://auth.gog.com/token
  Content-Type: application/x-www-form-urlencoded
  
  client_id={CLIENT_ID}
  &client_secret={CLIENT_SECRET}
  &grant_type=authorization_code
  &code={AUTH_CODE}
  &redirect_uri={REDIRECT_URI}
```

**Key Endpoints**:
```ruby
# Get owned games
GET https://embed.gog.com/account/getFilteredProducts
  ?mediaType=1
  Authorization: Bearer {ACCESS_TOKEN}

# Get game details
GET https://api.gog.com/products/{GAME_ID}
  ?expand=downloads,expanded_dlcs,description,screenshots

# Get user data
GET https://embed.gog.com/userData.json
  Authorization: Bearer {ACCESS_TOKEN}
```

**Rate Limits**: 
- Not officially documented
- Implement conservative rate limiting (100 req/min)

**Notes**:
- OAuth tokens expire, implement refresh token flow
- Some endpoints require Galaxy client
- GOG has both public API and Galaxy API

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 2)

---

### Epic Games Store API

**Purpose**: Access Epic Games library

**Documentation**: https://dev.epicgames.com/docs/

**Authentication**: OAuth 2.0

**Setup**:
1. Register at https://dev.epicgames.com/
2. Create application in Developer Portal
3. Add to `.env`: `EPIC_CLIENT_ID` and `EPIC_CLIENT_SECRET`

**OAuth Flow**:
```ruby
# Authorization URL
https://www.epicgames.com/id/authorize
  ?client_id={CLIENT_ID}
  &response_type=code
  &scope=basic_profile friends_list presence

# Token exchange
POST https://api.epicgames.dev/epic/oauth/v1/token
  Authorization: Basic {BASE64(CLIENT_ID:CLIENT_SECRET)}
  Content-Type: application/x-www-form-urlencoded
  
  grant_type=authorization_code
  &code={AUTH_CODE}
```

**Key Endpoints**:
```ruby
# Get user info
GET https://api.epicgames.dev/epic/id/v1/accounts/{ACCOUNT_ID}
  Authorization: Bearer {ACCESS_TOKEN}

# Get owned items
GET https://api.epicgames.dev/epic/ecom/v1/platforms/EPIC/identities/{ACCOUNT_ID}/ownership
  Authorization: Bearer {ACCESS_TOKEN}
```

**Rate Limits**: 
- Standard rate limiting applies
- Monitor via response headers

**Notes**:
- Epic Games API is less documented than Steam
- May need to use Epic Games Launcher API
- Consider using web scraping as backup (check ToS)

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 2)

---

### Xbox / Microsoft Gaming API

**Purpose**: Access Xbox Game Pass library, achievements

**Documentation**: https://learn.microsoft.com/en-us/gaming/

**Authentication**: Microsoft OAuth 2.0

**Setup**:
1. Register app in Azure AD
2. Configure Xbox Live services
3. Add credentials to `.env`

**Key Features**:
- Xbox Game Pass library
- Achievement tracking
- Gamerscore
- Cross-play detection

**Implementation Priority**: ⭐⭐⭐ (Phase 5)

---

### PlayStation Network API

**Purpose**: Access PlayStation library and trophies

**Documentation**: No official public API

**Authentication**: Unofficial methods available

**Notes**:
- No official API available
- Community has reverse-engineered APIs
- Use with caution, may violate ToS
- Consider unofficial libraries (e.g., PSN-API npm package)

**Implementation Priority**: ⭐⭐ (Phase 5, Low priority due to API restrictions)

---

### Itch.io API

**Purpose**: Access Itch.io library (indie games)

**Documentation**: https://itch.io/docs/api/overview

**Authentication**: API Key

**Setup**:
1. Generate API key in itch.io settings
2. Add to `.env`: `ITCHIO_API_KEY`

**Key Endpoints**:
```ruby
# Get user's owned games
GET https://itch.io/api/1/{API_KEY}/my-games

# Get game details
GET https://itch.io/api/1/{API_KEY}/game/{GAME_ID}
```

**Implementation Priority**: ⭐⭐⭐ (Phase 5)

---

## 🎲 Game Data APIs

### IGDB (Internet Game Database)

**Purpose**: Comprehensive game metadata, cover art, screenshots

**Documentation**: https://api-docs.igdb.com/

**Authentication**: OAuth via Twitch (IGDB owned by Twitch)

**Setup**:
1. Register app on Twitch Developer Portal
2. Get Client ID and Secret
3. Add to `.env`: `IGDB_CLIENT_ID` and `IGDB_CLIENT_SECRET`

**Authentication**:
```ruby
POST https://id.twitch.tv/oauth2/token
  ?client_id={CLIENT_ID}
  &client_secret={CLIENT_SECRET}
  &grant_type=client_credentials
```

**Key Endpoints**:
```ruby
# Search games
POST https://api.igdb.com/v4/games
  Client-ID: {CLIENT_ID}
  Authorization: Bearer {ACCESS_TOKEN}
  
  fields name,cover,genres,release_dates;
  search "Hollow Knight";
  limit 10;

# Get game details
POST https://api.igdb.com/v4/games
  fields *;
  where id = 1234;

# Get cover art
POST https://api.igdb.com/v4/covers
  fields *;
  where game = 1234;

# Get screenshots
POST https://api.igdb.com/v4/screenshots
  fields *;
  where game = 1234;
```

**Rate Limits**: 
- 4 requests per second
- Implement request queuing

**Image URLs**:
```
https://images.igdb.com/igdb/image/upload/t_cover_big/{image_id}.jpg
```

**Implementation Priority**: ⭐⭐⭐⭐⭐ (Phase 2, Critical for metadata)

---

### RAWG Video Games Database API

**Purpose**: Alternative game metadata source

**Documentation**: https://rawg.io/apidocs

**Authentication**: API Key

**Setup**:
1. Sign up at https://rawg.io/
2. Get API key from API settings
3. Add to `.env`: `RAWG_API_KEY`

**Key Endpoints**:
```ruby
# Search games
GET https://api.rawg.io/api/games
  ?key={API_KEY}
  &search={QUERY}

# Get game details
GET https://api.rawg.io/api/games/{GAME_ID}
  ?key={API_KEY}

# Get game screenshots
GET https://api.rawg.io/api/games/{GAME_ID}/screenshots
  ?key={API_KEY}
```

**Rate Limits**: 
- 20,000 requests per month (free tier)
- Implement caching

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 2, Backup to IGDB)

---

### HowLongToBeat

**Purpose**: Game completion time estimates

**Documentation**: No official API

**Authentication**: None (web scraping)

**Options**:
1. **Community API**: https://github.com/ckatzorke/howlongtobeat
2. **Web Scraping**: Scrape https://howlongtobeat.com/ (respect robots.txt)
3. **Unofficial NPM Package**: howlongtobeat npm package

**Implementation**:
```ruby
# Use community library or build scraper
# Cache results aggressively (data changes rarely)
```

**Rate Limits**: 
- Be very conservative
- Cache results for at least 30 days
- Consider building our own database from community contributions

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 1, Important for backlog management)

---

### IsThereAnyDeal

**Purpose**: Price tracking, deal alerts, historical pricing

**Documentation**: https://docs.isthereanydeal.com/

**Authentication**: API Key

**Setup**:
1. Apply for API access: https://isthereanydeal.com/apps/
2. Get API key
3. Add to `.env`: `ITAD_API_KEY`

**Key Endpoints**:
```ruby
# Get current prices
POST https://api.isthereanydeal.com/v01/game/prices/
  ?key={API_KEY}
  &plains={GAME_PLAINS}

# Get historical low
POST https://api.isthereanydeal.com/v01/game/lowest/
  ?key={API_KEY}
  &plains={GAME_PLAINS}

# Get price history
POST https://api.isthereanydeal.com/v01/game/history/
  ?key={API_KEY}
  &plains={GAME_PLAINS}

# Search for game
GET https://api.isthereanydeal.com/v02/search/search/
  ?key={API_KEY}
  &q={QUERY}
```

**Rate Limits**: 
- Reasonable rate limiting
- Cache price data for at least 1 hour

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 4, Price tracking feature)

---

## 🤖 AI Service APIs

### OpenAI API

**Purpose**: Natural language processing, recommendations, chat

**Documentation**: https://platform.openai.com/docs/

**Authentication**: API Key

**Setup**:
1. Create account at https://platform.openai.com/
2. Generate API key
3. Add to `.env`: `OPENAI_API_KEY`

**Key Endpoints**:
```ruby
# Chat completions (GPT-4, GPT-3.5)
POST https://api.openai.com/v1/chat/completions
  Authorization: Bearer {API_KEY}
  Content-Type: application/json
  
  {
    "model": "gpt-4-turbo",
    "messages": [
      {"role": "system", "content": "You are a gaming recommendation assistant"},
      {"role": "user", "content": "Recommend games similar to Hollow Knight"}
    ],
    "temperature": 0.7,
    "max_tokens": 500
  }

# Embeddings (for semantic search)
POST https://api.openai.com/v1/embeddings
  {
    "model": "text-embedding-3-small",
    "input": "Game description text"
  }
```

**Pricing** (as of 2026):
- GPT-4 Turbo: ~$0.01 per 1K tokens (input), ~$0.03 per 1K tokens (output)
- GPT-3.5 Turbo: ~$0.0005 per 1K tokens (input), ~$0.0015 per 1K tokens (output)
- Embeddings: ~$0.00002 per 1K tokens

**Rate Limits**: 
- Varies by tier (10,000 RPM for standard)
- Implement retry logic with exponential backoff

**Implementation Priority**: ⭐⭐⭐⭐⭐ (Phase 1, Critical)

---

### Anthropic Claude API

**Purpose**: Alternative AI for complex reasoning, analysis

**Documentation**: https://docs.anthropic.com/

**Authentication**: API Key

**Setup**:
1. Sign up at https://console.anthropic.com/
2. Generate API key
3. Add to `.env`: `ANTHROPIC_API_KEY`

**Key Endpoints**:
```ruby
# Messages API
POST https://api.anthropic.com/v1/messages
  x-api-key: {API_KEY}
  anthropic-version: 2023-06-01
  Content-Type: application/json
  
  {
    "model": "claude-3-sonnet-20240229",
    "max_tokens": 1024,
    "messages": [
      {"role": "user", "content": "Analyze this game library and recommend"}
    ]
  }
```

**Pricing** (as of 2026):
- Claude 3 Opus: ~$15 per MTok (input), ~$75 per MTok (output)
- Claude 3 Sonnet: ~$3 per MTok (input), ~$15 per MTok (output)
- Claude 3 Haiku: ~$0.25 per MTok (input), ~$1.25 per MTok (output)

**Rate Limits**: 
- Varies by tier
- Generally more generous than OpenAI

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 1, Fallback/Alternative to OpenAI)

---

## 📧 Communication APIs (Future)

### SendGrid

**Purpose**: Transactional emails (notifications, alerts)

**Documentation**: https://docs.sendgrid.com/

**Setup**: Sign up, get API key

**Implementation Priority**: ⭐⭐⭐ (Phase 4)

---

### Twilio

**Purpose**: SMS notifications (optional)

**Documentation**: https://www.twilio.com/docs

**Implementation Priority**: ⭐ (Future, low priority)

---

## 💳 Payment APIs (Future)

### Stripe

**Purpose**: Premium subscriptions, payment processing

**Documentation**: https://stripe.com/docs/api

**Setup**:
1. Create Stripe account
2. Get publishable and secret keys
3. Configure webhook endpoint

**Implementation Priority**: ⭐⭐⭐⭐ (Phase 4, Premium tier)

---

## 📊 Analytics & Monitoring

### Sentry

**Purpose**: Error tracking and monitoring

**Documentation**: https://docs.sentry.io/

**Setup**:
1. Create Sentry project
2. Get DSN
3. Add to `.env`: `SENTRY_DSN`

**Implementation Priority**: ⭐⭐⭐⭐⭐ (Phase 1, Production requirement)

---

## 🔧 Implementation Strategy

### Phase 1 (MVP)
- ✅ Steam API (critical)
- ✅ OpenAI API (critical)
- ✅ IGDB API (important)
- ✅ Sentry (production)

### Phase 2 (Multi-Platform)
- GOG API
- Epic Games API
- RAWG API (backup)
- HowLongToBeat integration

### Phase 3 (Enhanced Features)
- IsThereAnyDeal API
- Anthropic API (alternative AI)

### Phase 4 (Premium)
- Stripe API
- SendGrid API

### Phase 5 (Expansion)
- Xbox API
- PlayStation (if possible)
- Itch.io API
- Additional platforms

---

## 🛡️ Best Practices

### Rate Limiting
```ruby
# Implement rate limiter class
class ApiRateLimiter
  def initialize(max_requests:, period:)
    @max_requests = max_requests
    @period = period
  end
  
  def throttle(&block)
    # Use Redis to track request counts
    # Implement exponential backoff
    # Retry with Sidekiq if rate limited
  end
end
```

### Caching Strategy
```ruby
# Cache external API responses aggressively
# Game metadata: 24 hours
Rails.cache.fetch("game:#{game_id}", expires_in: 24.hours) do
  fetch_from_api(game_id)
end

# User library: 1 hour
Rails.cache.fetch("library:#{user_id}", expires_in: 1.hour) do
  fetch_library(user_id)
end

# Prices: 6 hours
Rails.cache.fetch("prices:#{game_id}", expires_in: 6.hours) do
  fetch_prices(game_id)
end
```

### Error Handling
```ruby
def fetch_with_retry(max_retries: 3)
  retries = 0
  begin
    yield
  rescue RateLimitError => e
    retries += 1
    if retries <= max_retries
      sleep(2 ** retries) # Exponential backoff
      retry
    else
      Sentry.capture_exception(e)
      nil
    end
  rescue ApiError => e
    Sentry.capture_exception(e)
    nil
  end
end
```

### API Key Management
- Never commit API keys to version control
- Use Rails credentials for production
- Rotate keys regularly
- Monitor API usage and costs
- Implement usage alerts

### Webhook Security
```ruby
# Verify webhook signatures
def verify_webhook_signature(payload, signature)
  computed = OpenSSL::HMAC.hexdigest(
    OpenSSL::Digest.new('sha256'),
    ENV['WEBHOOK_SECRET'],
    payload
  )
  ActiveSupport::SecurityUtils.secure_compare(computed, signature)
end
```

---

## 📚 Additional Resources

- [Steam Web API Documentation](https://developer.valvesoftware.com/wiki/Steam_Web_API)
- [IGDB API Guide](https://api-docs.igdb.com/)
- [OpenAI Best Practices](https://platform.openai.com/docs/guides/production-best-practices)
- [Rate Limiting Strategies](https://stripe.com/blog/rate-limiters)

---

*Last Updated: January 14, 2026*
