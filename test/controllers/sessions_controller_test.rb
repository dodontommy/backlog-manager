require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should handle oauth callback successfully" do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google] = OmniAuth::AuthHash.new({
      provider: "google",
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

    get "/auth/google/callback"
    assert_redirected_to root_path
    assert_not_nil session[:user_id]
    assert_equal "Successfully authenticated with Google!", flash[:notice]
  end

  test "should handle authentication failure" do
    get "/auth/failure?message=invalid_credentials"
    assert_redirected_to root_path
    assert_equal "Authentication failed: invalid_credentials", flash[:alert]
  end

  test "should destroy session on logout" do
    # Set up session
    post "/auth/google/callback"
    assert_not_nil session[:user_id]

    # Logout
    delete logout_path
    assert_nil session[:user_id]
    assert_redirected_to root_path
    assert_equal "Successfully logged out.", flash[:notice]
  end
end
