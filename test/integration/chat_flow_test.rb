require "test_helper"

class ChatFlowTest < ActionDispatch::IntegrationTest
  def setup
    # Create test user
    @test_user = User.create!(
      email: "integration@example.com",
      username: "integrationuser",
      provider: "google_oauth2",
      uid: "integration123"
    )

    # Stub AnthropicService to avoid actual API calls
    @mock_service = mock("anthropic_service")
    @mock_service.stubs(:send_message).with do |message, &block|
      if block_given?
        # Simulate streaming response
        block.call({ type: "text", content: "I can help " })
        block.call({ type: "text", content: "with that!" })
        block.call({ type: "done" })
      end
      true
    end.returns("I can help with that!")
    AnthropicService.stubs(:new).returns(@mock_service)
  end

  def teardown
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

  test "complete chat conversation flow" do
    sign_in_as(@test_user)

    logged_in_user = User.last

    # First message creates session
    assert_difference "ChatSession.count", 1 do
      post chat_messages_path, params: { message: "Show me my backlog" }, as: :json
    end

    assert_response :success

    # Verify session was created
    session = logged_in_user.chat_sessions.last
    assert_not_nil session
  end

  test "chat persists across requests" do
    sign_in_as(@test_user)

    logged_in_user = User.last

    # First message creates session
    post chat_messages_path, params: { message: "Hello" }, as: :json
    assert_response :success

    first_session = logged_in_user.chat_sessions.last
    first_session_id = first_session.id

    # Second message should reuse same session
    assert_no_difference "ChatSession.count" do
      post chat_messages_path, params: { message: "Show my games", session_id: first_session_id }, as: :json
    end

    assert_response :success

    # Should still be using the same session
    assert_equal first_session_id, logged_in_user.chat_sessions.last.id
  end

  test "expired session creates new session" do
    sign_in_as(@test_user)

    logged_in_user = User.last

    # Create expired session
    expired_session = ChatSession.create!(
      user: logged_in_user,
      expires_at: 1.hour.ago
    )

    # Try to use expired session
    assert_difference "ChatSession.count", 1 do
      post chat_messages_path,
        params: { message: "New chat", session_id: expired_session.id },
        as: :json
    end

    assert_response :success

    # Should have created a new session
    new_session = logged_in_user.chat_sessions.last
    assert_not_equal expired_session.id, new_session.id
  end
end
