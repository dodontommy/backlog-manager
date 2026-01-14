# frozen_string_literal: true

module GamePlatforms
  # Base class for game platform integrations (Steam, GOG, Epic, etc.)
  class BasePlatform
    attr_reader :access_token

    def initialize(access_token)
      @access_token = access_token
    end

    # Fetch user's game library from the platform
    # @return [Array<Hash>] Array of game hashes
    def fetch_library
      raise NotImplementedError, "Subclass must implement fetch_library"
    end

    # Fetch details for a specific game
    # @param game_id [String] Platform-specific game identifier
    # @return [Hash] Game details
    def fetch_game_details(game_id)
      raise NotImplementedError, "Subclass must implement fetch_game_details"
    end

    # Check if the service is properly configured
    # @return [Boolean]
    def configured?
      access_token.present?
    end

    private

    def platform_name
      self.class.name.demodulize.underscore.gsub("_platform", "")
    end
  end
end
