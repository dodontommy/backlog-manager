require "test_helper"
require "webmock/minitest"

class AnthropicServiceTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @session = ChatSession.create!(user: @user)
    @service = AnthropicService.new(@session)
  end

  def teardown
    WebMock.reset!
  end

  test "should initialize with session" do
    assert_equal @session, @service.session
  end

  test "should build messages from session history" do
    @session.add_message("user", "What should I play?")
    @session.add_message("assistant", "Let me check your backlog")

    messages = @service.send(:build_messages, "Tell me more")

    assert_equal 3, messages.length
    assert_equal "user", messages[0]["role"]
    assert_equal "What should I play?", messages[0]["content"]
    assert_equal "assistant", messages[1]["role"]
    assert_equal "user", messages[2]["role"]
    assert_equal "Tell me more", messages[2]["content"]
  end

  test "should send message to Anthropic API" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          id: "msg_123",
          type: "message",
          role: "assistant",
          content: [{ type: "text", text: "Here are your games..." }],
          stop_reason: "end_turn"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @service.send_message("What should I play?")

    assert_equal "Here are your games...", response
    assert_equal 2, @session.messages.length
  end

  test "should handle tool use in response" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          id: "msg_123",
          type: "message",
          role: "assistant",
          content: [
            { type: "text", text: "Let me check your backlog" },
            {
              type: "tool_use",
              id: "tool_123",
              name: "get_user_backlog",
              input: { status: "not_started" }
            }
          ],
          stop_reason: "tool_use"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
      .then.to_return(
        status: 200,
        body: {
          id: "msg_456",
          type: "message",
          role: "assistant",
          content: [{ type: "text", text: "You have 5 games in your backlog" }],
          stop_reason: "end_turn"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @service.send_message("What's in my backlog?")

    assert_includes response, "5 games"
  end

  test "should include tool definitions in API request" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          id: "msg_123",
          type: "message",
          role: "assistant",
          content: [{ type: "text", text: "Response" }],
          stop_reason: "end_turn"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    @service.send_message("Test")

    assert_requested(:post, "https://api.anthropic.com/v1/messages") do |req|
      body = JSON.parse(req.body)
      assert body["tools"].is_a?(Array)
      assert body["tools"].length == 6

      tool_names = body["tools"].map { |t| t["name"] }
      assert_includes tool_names, "get_user_backlog"
      assert_includes tool_names, "update_game_status"
    end
  end

  test "should handle API errors gracefully" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: "Internal Server Error")

    response = @service.send_message("Test")

    assert_includes response, "error"
  end
end
