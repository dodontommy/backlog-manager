# Gaming Curator AI Agent

**Phase 1: Local Prototype** - Your first AI gaming agent!

## What This Does

This agent connects to the IGDB (Internet Game Database) API and helps you discover games. It's a prototype that demonstrates:

- ✅ Connecting to gaming APIs (IGDB)
- ✅ Searching for games by name
- ✅ Getting game metadata (ratings, genres, descriptions)
- ✅ Running completely locally (no AWS needed yet!)

## Quick Start

### 1. Set up your IGDB credentials

Copy the example env file and add your credentials:

```bash
cp .env.example .env
# Edit .env and add your IGDB_CLIENT_ID and IGDB_CLIENT_SECRET
```

### 2. Install dependencies

```bash
# Using Python 3.11
python3.11 -m venv venv
source venv/bin/activate  # On macOS/Linux
pip install -r requirements.txt
```

### 3. Run the agent

```bash
# Make sure your .env file has your IGDB credentials
export $(cat .env | xargs)

# Run the agent
python3.11 gaming_curator.py
```

## What You'll See

The agent will:
1. Authenticate with IGDB using your credentials
2. Run a few test searches (Baldur's Gate 3, RPGs, Elden Ring)
3. Display game information from IGDB
4. Show you what's possible!

## Example Output

```
🎮 GAMING CURATOR AGENT - Phase 1 Prototype
============================================================

🤔 Analyzing: 'Show me games like Baldur's Gate 3'
🔍 Searching IGDB for: 'baldur's gate 3'

✨ Found 3 games:

1. Baldur's Gate 3
   ⭐ Rating: 96.2/100
   🎯 Genres: RPG, Strategy, Adventure
   📝 An epic story of adventure, survival, and companionship...

💡 Recommendation:
   Based on your interest in 'baldur's gate 3', I'd recommend
   'Baldur's Gate 3' - it seems like a great match!
```

## Next Steps

After Phase 1 works:

- **Phase 2**: Deploy to AWS Bedrock AgentCore Runtime
- **Phase 3**: Add the actual IGDB MCP server
- **Phase 4**: Add AI reasoning with Claude
- **Phase 5**: Add AgentCore Memory for learning preferences
- **Phase 6**: Integrate with Rails web app

## Architecture (Current)

```
User → gaming_curator.py → IGDB API → Game Data
```

## Architecture (Future)

```
Rails App → AWS AgentCore Runtime → Agent
                                    ↓
                                  Gateway → IGDB MCP Server → IGDB API
                                    ↓
                                  Memory (learns preferences)
                                    ↓
                                  Claude (AI reasoning)
```

## Troubleshooting

**"Missing IGDB credentials"**
- Make sure you've set IGDB_CLIENT_ID and IGDB_CLIENT_SECRET in your .env file
- Run `export $(cat .env | xargs)` to load them

**"Failed to authenticate with IGDB"**
- Check that your credentials are correct
- Make sure you registered your app at https://dev.twitch.tv/console

**"No games found"**
- IGDB might be rate limiting
- Try a different search term
- Wait a moment and try again

## Cost

**Phase 1: $0** - Everything runs locally!

When we deploy to AWS:
- Estimated $5-15/month for light use
- You'll set up budget alerts before deploying
