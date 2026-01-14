# frozen_string_literal: true

module GamePlatforms
  # Epic Games Store platform integration
  class EpicPlatform < BasePlatform
    BASE_URL = "https://api.epicgames.dev"

    # Fetch user's game library from Epic Games Store
    # @return [Array<Hash>] Array of game hashes
    def fetch_library
      # TODO: Implement Epic Games Store API integration
      # This would use Epic Games Store API
      []
    end

    # Fetch details for a specific game from Epic Games Store
    # @param game_id [String] Epic Games game ID
    # @return [Hash] Game details
    def fetch_game_details(game_id)
      # TODO: Implement Epic Games Store API integration
      {}
    end
  end
end
