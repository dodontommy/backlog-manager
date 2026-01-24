class ToolExecutor
  class UnknownToolError < StandardError; end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def execute(tool_name, parameters)
    case tool_name
    when "get_user_backlog"
      get_user_backlog(parameters)
    when "update_game_status"
      update_game_status(parameters)
    when "search_games", "get_game_details", "add_to_backlog", "get_recommendations"
      { message: "This tool will be implemented in Phase 2" }
    else
      raise UnknownToolError, "Unknown tool: #{tool_name}"
    end
  end

  private

  def get_user_backlog(parameters)
    query = user.user_games.includes(:game)

    # Filter by status if provided (use string keys)
    if parameters["status"].present?
      query = query.where(status: parameters["status"])
    end

    # Apply limit (default 50)
    limit = parameters["limit"].present? ? parameters["limit"].to_i : 50
    query = query.limit(limit)

    games = query.order(priority: :asc).map do |user_game|
      {
        id: user_game.id,  # user_game id, not game id
        game_id: user_game.game.id,
        title: user_game.game.title,  # use 'title' not 'name'
        status: user_game.status,
        priority: user_game.priority,
        hours_played: user_game.hours_played,
        notes: user_game.notes,
        platform: user_game.game.platform  # platform from game table
      }
    end

    { games: games }
  end

  def update_game_status(parameters)
    # Use string keys and user_game_id parameter
    user_game = user.user_games.find_by(id: parameters["user_game_id"])

    unless user_game
      return { success: false, error: "User game not found" }
    end

    # Build update attributes from parameters
    update_attrs = {}
    update_attrs[:status] = parameters["status"] if parameters["status"].present?
    update_attrs[:priority] = parameters["priority"] if parameters["priority"].present?
    update_attrs[:notes] = parameters["notes"] if parameters.key?("notes")  # Allow empty string

    if user_game.update(update_attrs)
      {
        success: true,
        id: user_game.id,
        game_id: user_game.game.id,
        status: user_game.status,
        priority: user_game.priority,
        notes: user_game.notes
      }
    else
      { success: false, error: user_game.errors.full_messages.join(", ") }
    end
  end
end
