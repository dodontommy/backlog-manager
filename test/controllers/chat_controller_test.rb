require "test_helper"

class ChatControllerTest < ActionDispatch::IntegrationTest
  def setup
    # Create test user manually instead of using fixtures
    @test_user = User.create!(
      email: "chattest@example.com",
      username: "chattestuser",
      provider: "google_oauth2",
      uid: "chattest123"
    )

    # Stub AnthropicService to avoid actual API calls
    @mock_service = mock("anthropic_service")
    @mock_service.stubs(:send_message).returns("Here's a test response from Claude!")
    AnthropicService.stubs(:new).returns(@mock_service)
  end

  def teardown
    # Clean up created users
    @test_user&.destroy
  end

  def sign_in_as(user)
    # Use OmniAuth callback to set session
    OmniAuth.config.test_mode = true
    auth_hash = OmniAuth::AuthHash.new({
      provider: user.provider,
      uid: user.uid,
      info: {
        email: user.email,
        name: user.username
      }
    })
    Rails.application.env_config["omniauth.auth"] = auth_hash
    get "/auth/google_oauth2/callback"
  end

  test "should get chat page" do
    sign_in_as(@test_user)
    get chat_path
    assert_response :success
  end

  test "should require authentication" do
    post chat_messages_path, params: { message: "Test" }, as: :json
    assert_response :unauthorized
  end

  test "should create new session if none exists" do
    sign_in_as(@test_user)
    assert_difference "ChatSession.count", 1 do
      post chat_messages_path, params: { message: "What should I play?" }, as: :json
    end

    assert_response :success
    json = JSON.parse(response.body)
    assert json["response"]
    assert json["session_id"]
  end

  test "should reuse existing session if not expired" do
    sign_in_as(@test_user)

    # Get the actual logged-in user (might be different due to test isolation issues)
    logged_in_user = User.last  # The user created by sign_in_as
    session = ChatSession.create!(user: logged_in_user)

    assert_no_difference "ChatSession.count" do
      post chat_messages_path,
        params: { message: "Tell me more", session_id: session.id },
        as: :json
    end

    assert_response :success
  end

  test "should create new session if expired" do
    sign_in_as(@test_user)

    # Get the actual logged-in user
    logged_in_user = User.last
    expired_session = ChatSession.create!(
      user: logged_in_user,
      expires_at: 1.hour.ago
    )

    assert_difference "ChatSession.count", 1 do
      post chat_messages_path,
        params: { message: "New chat", session_id: expired_session.id },
        as: :json
    end

    assert_response :success
  end

  test "should not access other users sessions" do
    sign_in_as(@test_user)
    other_user = User.create!(
      email: "other@example.com",
      username: "otheruser",
      provider: "google_oauth2",
      uid: "other123"
    )
    other_session = ChatSession.create!(user: other_user)

    post chat_messages_path,
      params: { message: "Test", session_id: other_session.id },
      as: :json

    # Should create new session instead
    assert_not_equal other_session.id, JSON.parse(response.body)["session_id"]

    # Clean up
    other_user.destroy
  end
end
