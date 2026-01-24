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

    # Filter by status if provided
    if parameters[:status].present?
      query = query.where(status: parameters[:status])
    end

    games = query.order(priority: :asc).map do |user_game|
      {
        id: user_game.game.id,
        name: user_game.game.title,
        status: user_game.status,
        priority: user_game.priority,
        hours_played: user_game.hours_played,
        notes: user_game.notes
      }
    end

    { games: games }
  end

  def update_game_status(parameters)
    game = Game.find_by(id: parameters[:game_id])

    unless game
      return { success: false, error: "Game not found" }
    end

    user_game = user.user_games.find_or_initialize_by(game: game)

    if user_game.update(status: parameters[:status])
      { success: true, status: user_game.status, game_id: game.id }
    else
      { success: false, error: user_game.errors.full_messages.join(", ") }
    end
  end
end
