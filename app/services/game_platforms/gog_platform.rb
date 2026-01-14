# frozen_string_literal: true

module GamePlatforms
  # GOG (Good Old Games) platform integration
  class GogPlatform < BasePlatform
    BASE_URL = "https://api.gog.com"

    # Fetch user's game library from GOG
    # @return [Array<Hash>] Array of game hashes
    def fetch_library
      # TODO: Implement GOG API integration
      # This would use GOG Galaxy API
      []
    end

    # Fetch details for a specific game from GOG
    # @param game_id [String] GOG game ID
    # @return [Hash] Game details
    def fetch_game_details(game_id)
      # TODO: Implement GOG API integration
      {}
    end
  end
end
