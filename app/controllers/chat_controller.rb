class ChatController < ApplicationController
  before_action :authenticate_user!

  def index
    # Render chat UI (will be implemented in Task 5)
  end

  def create
    session = find_or_create_session
    message = params[:message]

    if message.blank?
      return render json: { error: "Message cannot be blank" }, status: :unprocessable_entity
    end

    # Use AnthropicService to get response
    service = AnthropicService.new(session.user, session)
    response_text = service.send_message(message)

    render json: {
      response: response_text,
      session_id: session.id
    }
  rescue StandardError => e
    Rails.logger.error "Chat error: #{e.message}\n#{e.backtrace.join("\n")}"
    render json: { error: "An error occurred processing your message" }, status: :internal_server_error
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
