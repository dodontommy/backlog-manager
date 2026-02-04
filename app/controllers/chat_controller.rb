class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    # Render chat UI (will be implemented in Task 5)
  end

  def create
    # Set headers for SSE
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    session = find_or_create_session
    message = params[:message]

    if message.blank?
      response.stream.write("data: #{({ type: "error", content: "Message cannot be blank" }).to_json}\n\n")
      response.stream.close
      return
    end

    # Send session ID to frontend
    response.stream.write("data: #{({ type: "session_id", session_id: session.id }).to_json}\n\n")

    # Use AnthropicService with streaming
    service = AnthropicService.new(session.user, session)

    service.send_message(message) do |chunk|
      response.stream.write("data: #{chunk.to_json}\n\n")
    end

  rescue IOError
    # Client disconnected
  rescue StandardError => e
    Rails.logger.error "Chat error: #{e.message}\n#{e.backtrace.join("\n")}"
    response.stream.write("data: #{({ type: "error", content: "An error occurred" }).to_json}\n\n")
  ensure
    response.stream.close
  end

  private

  def find_or_create_session
    if params[:session_id].present?
      session = current_user.chat_sessions.find_by(id: params[:session_id])

      # Check if session is expired
      if session && !session.expired?
        return session
      end
    end

    # Create new session
    current_user.chat_sessions.create!
  end

  def authenticate_user!
    unless current_user
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
