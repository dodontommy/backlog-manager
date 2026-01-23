# frozen_string_literal: true

require "net/http"
require "json"

module GamePlatforms
  # Steam Web API integration service
  # Handles profile visibility checks and player data retrieval
  class SteamService
    BASE_URL = "https://api.steampowered.com"
    PLAYER_SUMMARIES_ENDPOINT = "/ISteamUser/GetPlayerSummaries/v0002/"

    def initialize(api_key: nil)
      @api_key = api_key || ENV.fetch("STEAM_API_KEY", nil)
    end

    # Fetch player summary including visibility state
    # @param steam_id [String] The 17-digit SteamID64
    # @return [Hash, nil] Hash with :visibility and :profile_configured, or nil on error
    def fetch_player_summary(steam_id)
      return nil unless @api_key.present?
      return nil unless valid_steam_id?(steam_id)

      uri = build_uri(PLAYER_SUMMARIES_ENDPOINT, steamids: steam_id)
      response = make_request(uri)

      return nil unless response

      parse_player_summary(response)
    rescue => e
      Rails.logger.error "Steam API error fetching player summary: #{e.message}"
      nil
    end

    # Check if a Steam ID is valid format (17 digits)
    # @param steam_id [String] The Steam ID to validate
    # @return [Boolean]
    def valid_steam_id?(steam_id)
      steam_id.present? && steam_id.match?(/\A\d{17}\z/)
    end

    private

    def build_uri(endpoint, params = {})
      uri = URI("#{BASE_URL}#{endpoint}")
      query_params = params.merge(key: @api_key, format: "json")
      uri.query = URI.encode_www_form(query_params)
      uri
    end

    def make_request(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 10
      http.open_timeout = 5

      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      if response.code == "200"
        JSON.parse(response.body)
      else
        Rails.logger.error "Steam API returned status #{response.code}: #{response.body}"
        nil
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      Rails.logger.error "Steam API timeout: #{e.message}"
      nil
    rescue JSON::ParserError => e
      Rails.logger.error "Steam API JSON parse error: #{e.message}"
      nil
    end

    def parse_player_summary(response)
      players = response.dig("response", "players")
      return nil if players.nil? || players.empty?

      player = players.first
      visibility_state = player["communityvisibilitystate"]
      profile_state = player["profilestate"]

      {
        visibility: parse_visibility_state(visibility_state),
        profile_configured: check_profile_configured(profile_state),
        persona_name: player["personaname"],
        avatar_url: player["avatarfull"],
        profile_url: player["profileurl"]
      }
    end

    # Map Steam's numeric visibility codes to our string values
    # @param state [Integer] Steam's communityvisibilitystate value
    # @return [String] One of: "public", "private", "friends_only", "unknown"
    def parse_visibility_state(state)
      case state
      when 1
        "private"
      when 2
        "friends_only"
      when 3
        "public"
      else
        "unknown"
      end
    end

    # Check if Steam community profile is configured
    # @param state [Integer] Steam's profilestate value
    # @return [Boolean] true if profile is configured (1), false otherwise (0 or nil)
    def check_profile_configured(state)
      state == 1
    end
  end
end
