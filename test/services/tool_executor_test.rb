require "test_helper"

class ToolExecutorTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @executor = ToolExecutor.new(@user)
  end

  test "should initialize with user" do
    assert_equal @user, @executor.user
  end

  test "should execute get_user_backlog" do
    # Clear any existing user_games for this user to ensure clean test
    @user.user_games.destroy_all

    # Create some test games for the user
    game1 = games(:one)
    game2 = games(:two)

    UserGame.create!(user: @user, game: game1, status: "backlog", priority: 1)
    UserGame.create!(user: @user, game: game2, status: "playing", priority: 2)

    result = @executor.execute("get_user_backlog", {})

    assert result.is_a?(Hash)
    assert result[:games].is_a?(Array)
    assert_equal 2, result[:games].length

    first_game = result[:games].first
    assert first_game[:name]
    assert first_game[:status]
    assert first_game[:priority]
  end

  test "should filter get_user_backlog by status" do
    # Clear any existing user_games for this user to ensure clean test
    @user.user_games.destroy_all

    game1 = games(:one)
    game2 = games(:two)

    UserGame.create!(user: @user, game: game1, status: "backlog")
    UserGame.create!(user: @user, game: game2, status: "completed")

    result = @executor.execute("get_user_backlog", { status: "backlog" })

    assert_equal 1, result[:games].length
    assert_equal "backlog", result[:games].first[:status]
  end

  test "should execute update_game_status" do
    # Clear any existing user_games for this user to ensure clean test
    @user.user_games.destroy_all

    game = games(:one)
    user_game = UserGame.create!(user: @user, game: game, status: "backlog")

    result = @executor.execute("update_game_status", {
      game_id: game.id,
      status: "playing"
    })

    assert result[:success]
    assert_equal "playing", result[:status]

    user_game.reload
    assert_equal "playing", user_game.status
  end

  test "should handle update_game_status for non-existent game" do
    result = @executor.execute("update_game_status", {
      game_id: 99999,
      status: "completed"
    })

    assert_not result[:success]
    assert result[:error]
  end

  test "should raise error for unknown tool" do
    error = assert_raises(ToolExecutor::UnknownToolError) do
      @executor.execute("invalid_tool", {})
    end

    assert_match /Unknown tool: invalid_tool/, error.message
  end

  test "should stub search_games for Phase 2" do
    result = @executor.execute("search_games", { query: "Zelda" })
    assert result[:message].include?("Phase 2")
  end

  test "should stub get_game_details for Phase 2" do
    result = @executor.execute("get_game_details", { game_id: 123 })
    assert result[:message].include?("Phase 2")
  end

  test "should stub add_to_backlog for Phase 2" do
    result = @executor.execute("add_to_backlog", { game_id: 123 })
    assert result[:message].include?("Phase 2")
  end

  test "should stub get_recommendations for Phase 2" do
    result = @executor.execute("get_recommendations", {})
    assert result[:message].include?("Phase 2")
  end
end
