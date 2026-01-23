require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should handle oauth callback successfully" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: "google_oauth2",
      uid: "12345",
      info: {
        email: "test@example.com",
        name: "Test User",
        image: "https://example.com/avatar.jpg"
      },
      credentials: {
        token: "mock_token",
        expires_at: Time.now.to_i + 3600
      }
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:google_oauth2]
    get "/auth/google_oauth2/callback"
    assert_redirected_to root_path
    assert_not_nil session[:user_id]
    assert_match(/Successfully authenticated/, flash[:notice])
  end

  test "should handle authentication failure" do
    get "/auth/failure?message=invalid_credentials"
    assert_redirected_to root_path
    assert_equal "Authentication failed: invalid_credentials", flash[:alert]
  end

  test "should destroy session on logout" do
    # Create a test user
    user = User.create!(
      email: "logout@example.com",
      username: "logoutuser",
      provider: "google_oauth2",
      uid: "logout123"
    )
    
    delete logout_path, env: { "rack.session" => { user_id: user.id } }
    
    # Verify logout
    assert_redirected_to root_path
    assert_equal "Successfully logged out.", flash[:notice]
  end

  # Steam OAuth tests
  test "should handle steam oauth callback with public profile" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new({
      provider: "steam",
      uid: "76561198012345678",
      info: {
        nickname: "TestSteamUser",
        name: "Test Steam User",
        image: "https://steamcdn-a.akamaihd.net/steamcommunity/public/images/avatars/fe/fef.jpg"
      },
      credentials: {},
      extra: {}
    })

    # Mock the Steam API call to return public profile
    GamePlatforms::SteamService.any_instance.stubs(:fetch_player_summary).returns({
      visibility: "public",
      profile_configured: true,
      persona_name: "TestSteamUser",
      avatar_url: "https://example.com/avatar.jpg",
      profile_url: "https://steamcommunity.com/id/test"
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:steam]
    get "/auth/steam/callback"
    
    assert_redirected_to root_path
    assert_not_nil session[:user_id]
    assert_match(/public and ready for game syncing/, flash[:notice])
    
    # Verify identity was created with Steam ID
    user = User.find(session[:user_id])
    identity = user.identities.find_by(provider: "steam")
    assert_not_nil identity
    assert_equal "76561198012345678", identity.steam_id
    assert_equal "public", identity.profile_visibility
  end

  test "should handle steam oauth callback with private profile" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new({
      provider: "steam",
      uid: "76561198087654321",
      info: {
        nickname: "TestSteamUser2",
        name: "Test Steam User 2"
      },
      credentials: {},
      extra: {}
    })

    # Mock the Steam API call to return private profile
    GamePlatforms::SteamService.any_instance.stubs(:fetch_player_summary).returns({
      visibility: "private",
      profile_configured: true,
      persona_name: "TestSteamUser2",
      avatar_url: "https://example.com/avatar.jpg",
      profile_url: "https://steamcommunity.com/id/test"
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:steam]
    get "/auth/steam/callback"
    
    assert_redirected_to root_path
    assert_not_nil session[:user_id]
    assert_match(/profile is set to Private/, flash[:alert])
    
    # Verify identity was created
    user = User.find(session[:user_id])
    identity = user.identities.find_by(provider: "steam")
    assert_not_nil identity
    assert_equal "private", identity.profile_visibility
  end

  test "should handle steam oauth callback with unconfigured profile" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new({
      provider: "steam",
      uid: "76561198011111111",
      info: {
        nickname: "TestSteamUser3"
      },
      credentials: {},
      extra: {}
    })

    # Mock the Steam API call to return unconfigured profile
    GamePlatforms::SteamService.any_instance.stubs(:fetch_player_summary).returns({
      visibility: "public",
      profile_configured: false,
      persona_name: "TestSteamUser3",
      avatar_url: "https://example.com/avatar.jpg",
      profile_url: "https://steamcommunity.com/id/test"
    })

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:steam]
    get "/auth/steam/callback"
    
    assert_redirected_to root_path
    assert_match(/community profile is not set up/, flash[:alert])
  end

  test "should handle steam oauth callback when API call fails" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:steam] = OmniAuth::AuthHash.new({
      provider: "steam",
      uid: "76561198022222222",
      info: {
        nickname: "TestSteamUser4"
      },
      credentials: {},
      extra: {}
    })

    # Mock the Steam API call to fail
    GamePlatforms::SteamService.any_instance.stubs(:fetch_player_summary).returns(nil)

    Rails.application.env_config["omniauth.auth"] = OmniAuth.config.mock_auth[:steam]
    get "/auth/steam/callback"
    
    assert_redirected_to root_path
    assert_match(/couldn't verify your profile visibility/, flash[:alert])
  end

  test "refresh_steam_profile should update profile visibility" do
    # Create a user with Steam identity
    user = User.create!(
      email: "steamuser@example.com",
      username: "steamuser",
      provider: "steam",
      uid: "76561198033333333"
    )
    
    identity = Identity.create!(
      user: user,
      provider: "steam",
      uid: "76561198033333333",
      steam_id: "76561198033333333",
      profile_visibility: "private"
    )

    # Mock the Steam API call
    GamePlatforms::SteamService.any_instance.stubs(:fetch_player_summary).returns({
      visibility: "public",
      profile_configured: true,
      persona_name: "TestSteamUser",
      avatar_url: "https://example.com/avatar.jpg",
      profile_url: "https://steamcommunity.com/id/test"
    })

    # Refresh Steam profile with user logged in
    post refresh_steam_profile_path, env: { "rack.session" => { user_id: user.id } }
    
    assert_redirected_to user_games_path
    assert_match(/public and ready for syncing/, flash[:notice])
    
    # Verify visibility was updated
    identity.reload
    assert_equal "public", identity.profile_visibility
  end

  test "refresh_steam_profile should handle missing steam connection" do
    user = User.create!(
      email: "nosteam@example.com",
      username: "nosteamuser",
      provider: "google_oauth2",
      uid: "nosteam123"
    )
    
    # Refresh without Steam connection
    post refresh_steam_profile_path, env: { "rack.session" => { user_id: user.id } }
    
    assert_redirected_to user_games_path
    assert_equal "No Steam account connected.", flash[:alert]
  end
end
