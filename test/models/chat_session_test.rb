require "test_helper"

class ChatSessionTest < ActiveSupport::TestCase
  test "should belong to user" do
    session = chat_sessions(:one)
    assert_respond_to session, :user
    assert_instance_of User, session.user
  end

  test "should require user" do
    session = ChatSession.new
    assert_not session.valid?
    assert_includes session.errors[:user], "must exist"
  end

  test "should initialize with empty messages array" do
    user = users(:one)
    session = ChatSession.create!(user: user)
    assert_equal [], session.messages
  end

  test "should add message to messages array" do
    session = chat_sessions(:one)
    session.add_message("user", "What games should I play?")

    assert_equal 1, session.messages.length
    message = session.messages.first
    assert_equal "user", message["role"]
    assert_equal "What games should I play?", message["content"]
  end

  test "should add assistant message with tool calls" do
    session = chat_sessions(:one)
    tool_calls = [{ "type" => "tool_use", "id" => "1", "name" => "get_user_backlog" }]
    session.add_message("assistant", "Let me check your backlog", tool_calls)

    message = session.messages.first
    assert_equal "assistant", message["role"]
    assert_equal tool_calls, message["tool_calls"]
  end

  test "should clear all messages" do
    session = chat_sessions(:one)
    session.add_message("user", "Hello")
    session.add_message("assistant", "Hi there")
    assert_equal 2, session.messages.length

    session.clear_messages
    assert_equal 0, session.messages.length
  end

  test "should not be expired when created" do
    user = users(:one)
    session = ChatSession.create!(user: user)
    assert_not session.expired?
  end

  test "should be expired after expiration time" do
    user = users(:one)
    session = ChatSession.create!(user: user, expires_at: 1.hour.ago)
    assert session.expired?
  end

  test "should set default expiration to 24 hours from now" do
    user = users(:one)
    session = ChatSession.create!(user: user)

    # Should expire roughly 24 hours from now (within 1 minute tolerance)
    expected_expiry = 24.hours.from_now
    assert_in_delta expected_expiry.to_i, session.expires_at.to_i, 60
  end
end
