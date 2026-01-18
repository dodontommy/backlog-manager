# Game Search (IGDB)

Search for games using the IGDB gaming curator agent.

## Instructions

Search for games in the IGDB database using the Python gaming curator agent:

1. First, check if the Python virtual environment exists:
   ```bash
   test -d agents/venv && echo "venv exists" || echo "venv missing"
   ```

2. If venv exists, activate and run a search:
   ```bash
   cd agents && source venv/bin/activate && python -c "
   import asyncio
   from gaming_curator import IGDBClient

   async def search():
       client = IGDBClient()
       results = await client.search_games('$ARGUMENTS')
       for game in results[:5]:
           print(f\"- {game.get('name', 'Unknown')} ({game.get('first_release_date', 'N/A')})\")

   asyncio.run(search())
   "
   ```

3. If venv doesn't exist, guide the user to set it up:
   ```
   cd agents
   python -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   cp env.example .env
   # Then add IGDB credentials to .env
   ```

## Argument
$ARGUMENTS
