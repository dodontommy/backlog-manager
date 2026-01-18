#!/usr/bin/env python3.11
"""
Gaming Curator Agent - Your AI gaming companion

This agent uses the IGDB MCP server to search games, analyze your preferences,
and make personalized recommendations.
"""

import os
import asyncio
import json

# IGDB MCP Server configuration
IGDB_CLIENT_ID = os.environ.get("IGDB_CLIENT_ID")
IGDB_CLIENT_SECRET = os.environ.get("IGDB_CLIENT_SECRET")

class GamingCuratorAgent:
    """
    An AI agent that curates game recommendations using IGDB data
    """
    
    def __init__(self):
        """Initialize the Gaming Curator with IGDB access"""
        if not IGDB_CLIENT_ID or not IGDB_CLIENT_SECRET:
            raise ValueError(
                "Missing IGDB credentials. Please set IGDB_CLIENT_ID and IGDB_CLIENT_SECRET"
            )
        
        self.client_id = IGDB_CLIENT_ID
        self.client_secret = IGDB_CLIENT_SECRET
        self.igdb_token = None
        
        # For now, we'll simulate MCP server connection
        # In production, this would connect to actual IGDB MCP server
        print("🎮 Gaming Curator Agent initialized!")
        print(f"   IGDB Client ID: {self.client_id[:10]}...")
    
    async def authenticate_igdb(self):
        """Get IGDB OAuth token"""
        import aiohttp
        
        url = "https://id.twitch.tv/oauth2/token"
        params = {
            "client_id": self.client_id,
            "client_secret": self.client_secret,
            "grant_type": "client_credentials"
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, params=params) as response:
                if response.status == 200:
                    data = await response.json()
                    self.igdb_token = data["access_token"]
                    print("✅ Successfully authenticated with IGDB!")
                    return True
                else:
                    print(f"❌ Failed to authenticate with IGDB: {response.status}")
                    return False
    
    async def search_games(self, query: str, limit: int = 5):
        """Search for games on IGDB"""
        if not self.igdb_token:
            await self.authenticate_igdb()
        
        import aiohttp
        
        url = "https://api.igdb.com/v4/games"
        headers = {
            "Client-ID": self.client_id,
            "Authorization": f"Bearer {self.igdb_token}"
        }
        
        # IGDB uses Apicalypse query language
        body = f'''
            search "{query}";
            fields name, summary, rating, genres.name, platforms.name, 
                   first_release_date, involved_companies.company.name;
            limit {limit};
        '''
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, headers=headers, data=body) as response:
                if response.status == 200:
                    games = await response.json()
                    return games
                else:
                    print(f"❌ IGDB API error: {response.status}")
                    return []
    
    async def get_game_details(self, game_id: int):
        """Get detailed information about a specific game"""
        if not self.igdb_token:
            await self.authenticate_igdb()
        
        import aiohttp
        
        url = "https://api.igdb.com/v4/games"
        headers = {
            "Client-ID": self.client_id,
            "Authorization": f"Bearer {self.igdb_token}"
        }
        
        body = f'''
            where id = {game_id};
            fields name, summary, storyline, rating, aggregated_rating,
                   genres.name, themes.name, platforms.name, 
                   first_release_date, involved_companies.company.name,
                   similar_games.name, game_modes.name;
        '''
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, headers=headers, data=body) as response:
                if response.status == 200:
                    games = await response.json()
                    return games[0] if games else None
                else:
                    return None
    
    async def recommend(self, user_prompt: str):
        """
        Main recommendation function - this is where the AI agent reasoning happens
        
        In a full implementation, this would:
        1. Use AI to understand user intent
        2. Query IGDB via MCP tools
        3. Reason about results
        4. Generate personalized recommendations
        """
        print(f"\n🤔 Analyzing: '{user_prompt}'")
        print("=" * 60)
        
        # For this prototype, we'll do a simple search
        # In production, an LLM would analyze the prompt and decide what to search
        
        # Extract game name from prompt (simple version)
        search_term = user_prompt.lower()
        
        # Common phrases to remove
        for phrase in ["what should i play", "recommend", "suggest", "like", "similar to"]:
            search_term = search_term.replace(phrase, "").strip()
        
        if not search_term:
            search_term = "baldur's gate"  # Default
        
        print(f"🔍 Searching IGDB for: '{search_term}'")
        games = await self.search_games(search_term, limit=3)
        
        if not games:
            print("\n❌ No games found!")
            return
        
        print(f"\n✨ Found {len(games)} games:\n")
        
        for i, game in enumerate(games, 1):
            print(f"{i}. {game.get('name', 'Unknown')}")
            
            # Rating
            if 'rating' in game:
                print(f"   ⭐ Rating: {game['rating']:.1f}/100")
            
            # Genres
            if 'genres' in game:
                genres = [g['name'] for g in game['genres']]
                print(f"   🎯 Genres: {', '.join(genres)}")
            
            # Summary
            if 'summary' in game:
                summary = game['summary'][:150] + "..." if len(game['summary']) > 150 else game['summary']
                print(f"   📝 {summary}")
            
            print()
        
        # In production, AI would analyze these results and generate
        # a personalized recommendation with reasoning
        print("💡 Recommendation:")
        print(f"   Based on your interest in '{search_term}', I'd recommend")
        print(f"   '{games[0]['name']}' - it seems like a great match!")
        
        return games


async def main():
    """Main entry point for the Gaming Curator agent"""
    
    print("\n" + "=" * 60)
    print("🎮 GAMING CURATOR AGENT - Phase 1 Prototype")
    print("=" * 60)
    print("\nThis agent connects to IGDB to help you discover games!")
    print("\nMake sure you've set these environment variables:")
    print("  - IGDB_CLIENT_ID")
    print("  - IGDB_CLIENT_SECRET")
    print()
    
    try:
        # Initialize agent
        agent = GamingCuratorAgent()
        
        # Test authentication
        success = await agent.authenticate_igdb()
        
        if not success:
            print("\n❌ Failed to connect to IGDB. Check your credentials.")
            return
        
        # Example queries to test
        test_queries = [
            "Show me games like Baldur's Gate 3",
            "Find RPG games",
            "Elden Ring"
        ]
        
        for query in test_queries:
            await agent.recommend(query)
            print("\n" + "-" * 60 + "\n")
            await asyncio.sleep(1)  # Be nice to the API
        
        print("\n✅ Phase 1 prototype complete!")
        print("\nNext steps:")
        print("  1. This works locally with IGDB!")
        print("  2. We'll add the actual IGDB MCP server")
        print("  3. Then add real AI reasoning with Claude")
        print("  4. Finally deploy to AWS Bedrock AgentCore")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())
