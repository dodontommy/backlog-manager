#!/usr/bin/env python3.11
"""
Interactive test for the Gaming Curator Agent

Run this to try different game searches!
"""

import os
import asyncio
from gaming_curator import GamingCuratorAgent

async def main():
    print("\n🎮 GAMING CURATOR - Interactive Test")
    print("=" * 60)
    
    # Initialize agent
    agent = GamingCuratorAgent()
    await agent.authenticate_igdb()
    
    # Test different searches
    test_searches = [
        "Baldur's Gate",
        "Elden Ring", 
        "Disco Elysium",
        "Hades",
        "Stardew Valley"
    ]
    
    print("\n📝 Testing different game searches...\n")
    
    for search_term in test_searches:
        print(f"\n{'='*60}")
        print(f"🔍 Searching for: {search_term}")
        print('='*60)
        
        games = await agent.search_games(search_term, limit=3)
        
        if games:
            print(f"\n✨ Found {len(games)} result(s):\n")
            for i, game in enumerate(games, 1):
                print(f"{i}. {game.get('name', 'Unknown')}")
                
                if 'rating' in game:
                    print(f"   ⭐ Rating: {game['rating']:.1f}/100")
                
                if 'genres' in game:
                    genres = [g['name'] for g in game['genres']]
                    print(f"   🎯 Genres: {', '.join(genres)}")
                
                if 'summary' in game and game['summary']:
                    summary = game['summary'][:120] + "..." if len(game['summary']) > 120 else game['summary']
                    print(f"   📝 {summary}")
                
                print()
        else:
            print("\n❌ No games found")
        
        await asyncio.sleep(0.5)  # Be nice to the API
    
    print("\n" + "="*60)
    print("✅ Test complete!")
    print("\nTry modifying the test_searches list to search for your favorite games!")
    print("="*60 + "\n")

if __name__ == "__main__":
    asyncio.run(main())
