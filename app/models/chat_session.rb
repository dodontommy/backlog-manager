class ChatSession < ApplicationRecord
  belongs_to :user

  before_validation :set_default_expiration, on: :create

  def add_message(role, content, tool_calls = nil)
    message = { "role" => role, "content" => content }
    message["tool_calls"] = tool_calls if tool_calls.present?

    self.messages = messages + [message]
    save!
  end

  def clear_messages
    update!(messages: [])
  end

  def expired?
    expires_at < Time.current
  end

  private

  def set_default_expiration
    self.expires_at ||= 24.hours.from_now
  end
end
