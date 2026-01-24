require "test_helper"
require "webmock/minitest"

class AnthropicServiceTest < ActiveSupport::TestCase
  def setup
    # Set up API key for tests before anything else
    @original_api_key = ENV["ANTHROPIC_API_KEY"]
    ENV["ANTHROPIC_API_KEY"] = "test-api-key-12345"

    @user = users(:one)
    @session = ChatSession.create!(user: @user)
    @service = AnthropicService.new(@user, @session)
  end

  def teardown
    WebMock.reset!
    if @original_api_key
      ENV["ANTHROPIC_API_KEY"] = @original_api_key
    else
      ENV.delete("ANTHROPIC_API_KEY")
    end
  end


  test "should initialize with user and chat_session" do
    assert_equal @user, @service.instance_variable_get(:@user)
    assert_equal @session, @service.instance_variable_get(:@chat_session)
    assert_not_nil @service.instance_variable_get(:@tool_executor)
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

  test "should send message to Anthropic API with system prompt" do
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

    # Verify system prompt was included
    assert_requested(:post, "https://api.anthropic.com/v1/messages") do |req|
      body = JSON.parse(req.body)
      assert_not_nil body["system"]
      assert_includes body["system"], "gaming backlog assistant"
    end
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

  test "should include tool definitions with wishlist status in API request" do
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
      assert_equal 6, body["tools"].length

      tool_names = body["tools"].map { |t| t["name"] }
      assert_includes tool_names, "get_user_backlog"
      assert_includes tool_names, "update_game_status"

      # Verify all status enums include "wishlist"
      body["tools"].each do |tool|
        next unless tool["input_schema"]["properties"]["status"]
        status_enum = tool["input_schema"]["properties"]["status"]["enum"]
        assert_includes status_enum, "wishlist", "Tool #{tool["name"]} missing wishlist status"
      end
    end
  end

  test "should handle API errors gracefully" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(status: 500, body: "Internal Server Error")

    response = @service.send_message("Test")

    assert_includes response, "error"
  end

  test "should use correct model name" do
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
      assert_equal "claude-sonnet-4-5-20250929", body["model"]
    end
  end

  test "should format tool results correctly for Anthropic API" do
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          id: "msg_123",
          type: "message",
          role: "assistant",
          content: [
            { type: "text", text: "Let me check" },
            {
              type: "tool_use",
              id: "tool_123",
              name: "get_user_backlog",
              input: { status: "backlog" }
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
          content: [{ type: "text", text: "Final response" }],
          stop_reason: "end_turn"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    @service.send_message("Test")

    # Verify tool result format on second request
    assert_requested(:post, "https://api.anthropic.com/v1/messages", times: 2) do |req|
      body = JSON.parse(req.body)
      messages = body["messages"]

      # Check if this is the second request (with tool results)
      tool_result_msg = messages.find { |m| m["content"].is_a?(Array) && m["content"].any? { |c| c["type"] == "tool_result" } }

      if tool_result_msg
        tool_result = tool_result_msg["content"].find { |c| c["type"] == "tool_result" }
        assert_not_nil tool_result
        assert_equal "tool_result", tool_result["type"]
        assert_not_nil tool_result["tool_use_id"]
        assert tool_result["content"].is_a?(String), "Tool result content should be a string"
      end

      true
    end
  end

  test "should prevent infinite recursion with max depth limit" do
    # Stub API to always return tool use (would cause infinite loop without depth limit)
    stub_request(:post, "https://api.anthropic.com/v1/messages")
      .to_return(
        status: 200,
        body: {
          id: "msg_123",
          type: "message",
          role: "assistant",
          content: [
            {
              type: "tool_use",
              id: "tool_123",
              name: "get_user_backlog",
              input: {}
            }
          ],
          stop_reason: "tool_use"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    response = @service.send_message("Test")

    # Should stop after MAX_TOOL_DEPTH iterations
    # With MAX_TOOL_DEPTH = 5, should make max 6 requests (initial + 5 tool iterations)
    assert_requested(:post, "https://api.anthropic.com/v1/messages", times: 6)
  end
end
