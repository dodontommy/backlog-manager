require "test_helper"
require "webmock/minitest"

module GamePlatforms
  class SteamServiceTest < ActiveSupport::TestCase
    setup do
      @service = SteamService.new(api_key: "test_api_key")
      @valid_steam_id = "76561198012345678"
    end

    test "valid_steam_id? returns true for valid 17-digit steam id" do
      assert @service.valid_steam_id?(@valid_steam_id)
    end

    test "valid_steam_id? returns false for invalid steam id" do
      assert_not @service.valid_steam_id?("invalid")
      assert_not @service.valid_steam_id?("12345")
      assert_not @service.valid_steam_id?("765611980123456789") # 18 digits
      assert_not @service.valid_steam_id?(nil)
      assert_not @service.valid_steam_id?("")
    end

    test "fetch_player_summary returns nil when api key is missing" do
      service = SteamService.new(api_key: nil)
      result = service.fetch_player_summary(@valid_steam_id)
      assert_nil result
    end

    test "fetch_player_summary returns nil for invalid steam id" do
      result = @service.fetch_player_summary("invalid")
      assert_nil result
    end

    test "fetch_player_summary returns parsed data for public profile" do
      stub_steam_api_success(@valid_steam_id, communityvisibilitystate: 3, profilestate: 1)

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_not_nil result
      assert_equal "public", result[:visibility]
      assert_equal true, result[:profile_configured]
      assert_equal "TestPlayer", result[:persona_name]
    end

    test "fetch_player_summary returns parsed data for private profile" do
      stub_steam_api_success(@valid_steam_id, communityvisibilitystate: 1, profilestate: 1)

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_not_nil result
      assert_equal "private", result[:visibility]
    end

    test "fetch_player_summary returns parsed data for friends only profile" do
      stub_steam_api_success(@valid_steam_id, communityvisibilitystate: 2, profilestate: 1)

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_not_nil result
      assert_equal "friends_only", result[:visibility]
    end

    test "fetch_player_summary returns unknown for unrecognized visibility state" do
      stub_steam_api_success(@valid_steam_id, communityvisibilitystate: 99, profilestate: 1)

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_not_nil result
      assert_equal "unknown", result[:visibility]
    end

    test "fetch_player_summary detects unconfigured profile" do
      stub_steam_api_success(@valid_steam_id, communityvisibilitystate: 3, profilestate: 0)

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_not_nil result
      assert_equal false, result[:profile_configured]
    end

    test "fetch_player_summary handles API errors gracefully" do
      stub_request(:get, /api.steampowered.com/)
        .to_return(status: 500, body: "Internal Server Error")

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_nil result
    end

    test "fetch_player_summary handles timeout errors" do
      stub_request(:get, /api.steampowered.com/)
        .to_timeout

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_nil result
    end

    test "fetch_player_summary handles empty response" do
      stub_request(:get, /api.steampowered.com/)
        .to_return(
          status: 200,
          body: { response: { players: [] } }.to_json,
          headers: { "Content-Type" => "application/json" }
        )

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_nil result
    end

    test "fetch_player_summary handles malformed JSON" do
      stub_request(:get, /api.steampowered.com/)
        .to_return(status: 200, body: "not json")

      result = @service.fetch_player_summary(@valid_steam_id)

      assert_nil result
    end

    private

    def stub_steam_api_success(steam_id, communityvisibilitystate:, profilestate:)
      response_body = {
        response: {
          players: [
            {
              steamid: steam_id,
              communityvisibilitystate: communityvisibilitystate,
              profilestate: profilestate,
              personaname: "TestPlayer",
              avatarfull: "https://example.com/avatar.jpg",
              profileurl: "https://steamcommunity.com/id/testplayer"
            }
          ]
        }
      }.to_json

      stub_request(:get, /api.steampowered.com/)
        .with(query: hash_including({ steamids: steam_id }))
        .to_return(
          status: 200,
          body: response_body,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end
