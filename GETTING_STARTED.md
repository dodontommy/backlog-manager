# Getting Started with What The Game

Welcome to **What The Game**! This guide will help you get up and running with the application, whether you're setting it up locally or deploying to production.

---

## 🚀 Quick Start (5 minutes)

### For End Users (Coming Soon)

Once deployed, using What The Game is simple:

1. **Sign up** for an account at https://whatthegame.com
2. **Connect your gaming platforms** (Steam, GOG, Epic)
3. **Sync your library** with one click
4. **Get AI recommendations** on what to play next!

*Note: The application is currently in development. This guide focuses on developer setup.*

---

## 💻 Developer Quick Start

### Prerequisites Check

Before starting, ensure you have:
- ✅ Ruby 3.2.3 or higher
- ✅ PostgreSQL 13 or higher
- ✅ Git
- ✅ A terminal/command prompt

Check your versions:
```bash
ruby -v   # Should show 3.2.3 or higher
psql --version  # Should show 13 or higher
git --version
```

### Installation (3 steps)

**1. Clone and Install**
```bash
git clone https://github.com/dodontommy/what-the-game.git
cd what-the-game
bundle install
```

**2. Setup Database**
```bash
rails db:create db:migrate
```

**3. Start Server**
```bash
rails server
```

Visit `http://localhost:3000` 🎉

---

## 🔑 API Keys Setup (Optional but Recommended)

To unlock all features, you'll need API keys from various services.

### Priority 1: Steam Integration

**Why you need it**: Import your Steam game library

**How to get it**:
1. Visit https://steamcommunity.com/dev/apikey
2. Sign in with your Steam account
3. Enter a domain name (use `localhost` for development)
4. Copy your API key

**Add to `.env`**:
```bash
cp .env.example .env
# Edit .env and add:
STEAM_API_KEY=your_key_here
```

### Priority 2: AI Recommendations

**Why you need it**: Get intelligent game recommendations

**Choose one (or both)**:

#### Option A: OpenAI (GPT-4)
1. Visit https://platform.openai.com/api-keys
2. Create an account and add billing
3. Create a new API key
4. Add to `.env`:
   ```bash
   OPENAI_API_KEY=sk-your-key-here
   OPENAI_MODEL=gpt-4-turbo-preview
   ```

**Cost**: ~$0.02 per recommendation (GPT-4), ~$0.002 (GPT-3.5)

#### Option B: Anthropic (Claude)
1. Visit https://console.anthropic.com/
2. Create an account and add billing
3. Generate API key
4. Add to `.env`:
   ```bash
   ANTHROPIC_API_KEY=sk-ant-your-key-here
   ANTHROPIC_MODEL=claude-3-sonnet-20240229
   ```

**Cost**: ~$0.015 per recommendation (Claude Sonnet)

### Priority 3: Additional Platforms (Phase 2)

**GOG (Good Old Games)**
- Register at: https://devportal.gog.com/
- Add credentials to `.env`

**Epic Games Store**
- Register at: https://dev.epicgames.com/
- Add credentials to `.env`

---

## 📖 Understanding the Application

### Key Concepts

**1. User**
- Your account in the system
- Can connect multiple gaming platforms
- Has a unified game library

**2. Game**
- A video game from any platform
- Includes metadata: title, genre, developer, etc.
- Can exist on multiple platforms

**3. User Game (Backlog Entry)**
- A game in YOUR library
- Status: backlog, playing, completed, abandoned, wishlist
- Tracks: hours played, completion %, priority

**4. Game Service**
- Connection to a gaming platform (Steam, GOG, Epic)
- Stores OAuth tokens securely
- Syncs your library automatically

**5. Recommendation**
- AI-generated suggestion
- Includes: match score, reasoning, context
- Based on your play history and preferences

### Application Flow

```
1. Connect Platform
   ↓
2. Sync Library
   (Imports all your games)
   ↓
3. Games Added to Database
   (Unified across platforms)
   ↓
4. Request Recommendations
   (AI analyzes your library)
   ↓
5. Get Suggestions
   (Personalized game recommendations)
   ↓
6. Manage Backlog
   (Track progress, update status)
```

---

## 🎮 Basic Usage Examples

### Example 1: Syncing Your Steam Library

Once you have a Steam API key:

```ruby
# In Rails console (rails c)
user = User.create!(email: "you@example.com", username: "gamer123")

# Create Steam service connection
service = user.game_services.create!(
  service_name: 'steam',
  external_user_id: 'YOUR_STEAM_ID'
)

# Sync library (will be a background job in production)
GamePlatforms::SteamPlatform.new(service).fetch_library
```

### Example 2: Getting AI Recommendations

```ruby
# In Rails console
user = User.find_by(email: "you@example.com")

# Generate recommendations
service = AiServices::RecommendationService.new(user)
recommendations = service.generate_recommendations(limit: 5)

# View recommendations
recommendations.each do |rec|
  puts "#{rec.game.title} - Score: #{rec.score}"
  puts "Reason: #{rec.reason}"
  puts "---"
end
```

### Example 3: Managing Your Backlog

```ruby
# Add a game to backlog
user = User.first
game = Game.find_by(title: "Hades")

user_game = user.user_games.create!(
  game: game,
  status: 'backlog',
  priority: 8
)

# Update when you start playing
user_game.update!(
  status: 'playing',
  hours_played: 2.5
)

# Mark as completed
user_game.update!(
  status: 'completed',
  completion_percentage: 100,
  hours_played: 25
)
```

---

## 🧪 Testing Your Setup

### 1. Run the Test Suite

```bash
rails test
```

Expected output:
```
Running 15 tests in a single process
...............

Finished in 2.345s
15 tests, 45 assertions, 0 failures, 0 errors, 0 skips
```

### 2. Check Code Quality

```bash
bin/rubocop        # Style check
bin/brakeman       # Security check
bin/bundler-audit  # Dependency check
```

### 3. Verify Database

```bash
rails db:migrate:status
```

Should show all migrations as "up".

### 4. Check Routes

```bash
rails routes
```

Should display all available endpoints.

---

## 🐛 Troubleshooting

### Common Issues

**Issue: Database connection error**
```
Error: could not connect to server: Connection refused
```

**Solution**:
```bash
# Check if PostgreSQL is running
sudo service postgresql status

# Start PostgreSQL
sudo service postgresql start
```

---

**Issue: Bundle install fails**
```
Error: An error occurred while installing pg (1.5.4)
```

**Solution**:
```bash
# Install PostgreSQL development headers
sudo apt-get install libpq-dev  # Ubuntu/Debian
brew install postgresql@15       # macOS
```

---

**Issue: Rails server won't start**
```
Error: A server is already running
```

**Solution**:
```bash
# Kill existing server
kill $(cat tmp/pids/server.pid)

# Or remove PID file
rm tmp/pids/server.pid
```

---

**Issue: Steam API returns 403 Forbidden**

**Solution**:
- Verify your API key is correct
- Check that you're using the correct Steam ID format
- Ensure you haven't exceeded rate limits (100,000 calls/day)

---

**Issue: AI recommendations not working**

**Solution**:
```bash
# Check if API key is set
echo $OPENAI_API_KEY  # or $ANTHROPIC_API_KEY

# Verify in .env file
cat .env | grep API_KEY

# Test API connection
rails runner "puts OpenAI::Client.new.models.list"
```

---

## 📚 Next Steps

### For Developers

1. **Read the Architecture** → [ARCHITECTURE.md](ARCHITECTURE.md)
2. **Check the Roadmap** → [ROADMAP.md](ROADMAP.md)
3. **Explore AI Features** → [AI_FEATURES.md](AI_FEATURES.md)
4. **Review API Docs** → [API.md](API.md)
5. **Contributing Guide** → [CONTRIBUTING.md](CONTRIBUTING.md)

### For Users (Future)

1. **Create an Account** - Sign up at whatthegame.com
2. **Connect Platforms** - Link Steam, GOG, Epic accounts
3. **Sync Libraries** - Import your games with one click
4. **Get Recommendations** - Ask AI what to play next
5. **Manage Backlog** - Track your gaming progress

---

## 🎯 Your First Feature

Want to contribute? Here's a simple first task:

**Task**: Add a "favorite genre" field to User model

**Steps**:
1. Create migration:
   ```bash
   rails g migration AddFavoriteGenreToUsers favorite_genre:string
   rails db:migrate
   ```

2. Add validation to model:
   ```ruby
   # app/models/user.rb
   validates :favorite_genre, inclusion: { 
     in: %w[RPG Action Strategy Puzzle Adventure],
     allow_nil: true
   }
   ```

3. Add test:
   ```ruby
   # test/models/user_test.rb
   test "should allow valid favorite genre" do
     user = users(:one)
     user.favorite_genre = "RPG"
     assert user.save
   end
   ```

4. Run tests:
   ```bash
   rails test test/models/user_test.rb
   ```

5. Commit:
   ```bash
   git checkout -b feature/add-favorite-genre
   git add .
   git commit -m "feat(user): add favorite genre field"
   git push origin feature/add-favorite-genre
   ```

Congratulations! You've made your first contribution! 🎉

---

## 💡 Tips for Success

### Development Tips

1. **Use Rails Console** - `rails c` is your friend for testing
2. **Check Logs** - `tail -f log/development.log` for debugging
3. **Run Tests Often** - Catch issues early
4. **Use Git Branches** - Keep main branch clean
5. **Read Existing Code** - Learn from what's there

### AI Integration Tips

1. **Start Simple** - Test with basic prompts first
2. **Cache Everything** - AI calls are expensive
3. **Handle Errors** - APIs can fail, plan for it
4. **Monitor Costs** - Keep an eye on API usage
5. **Test Prompts** - Iterate on prompt engineering

### Database Tips

1. **Use Migrations** - Never edit schema.rb directly
2. **Add Indexes** - For frequently queried columns
3. **Use Transactions** - For multi-step operations
4. **Test Rollbacks** - Ensure migrations are reversible
5. **Backup Data** - Before risky operations

---

## 🆘 Getting Help

### Resources

- **Documentation**: Start with [README.md](README.md)
- **Issues**: Check [GitHub Issues](https://github.com/dodontommy/what-the-game/issues)
- **Discussions**: Join [GitHub Discussions](https://github.com/dodontommy/what-the-game/discussions)
- **Rails Guides**: https://guides.rubyonrails.org/
- **Ruby Docs**: https://ruby-doc.org/

### Support Channels

1. **Check Documentation First** - Most answers are there
2. **Search Existing Issues** - Someone may have had the same problem
3. **Open a Discussion** - For general questions
4. **Open an Issue** - For bugs or feature requests
5. **Join the Community** - Discord/Slack (coming soon)

---

## 🎊 You're Ready!

You now have everything you need to start using and developing What The Game!

**Quick Links**:
- 📖 [Full Documentation](README.md)
- 🏗️ [Architecture Guide](ARCHITECTURE.md)
- 🗺️ [Roadmap](ROADMAP.md)
- 🤖 [AI Features](AI_FEATURES.md)
- 🤝 [Contributing](CONTRIBUTING.md)

**Happy Gaming! 🎮**

---

*Last Updated: 2026-01-14*
