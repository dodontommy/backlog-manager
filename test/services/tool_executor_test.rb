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
    assert first_game[:title]  # Changed from :name to :title
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

    # Use string keys like Anthropic API
    result = @executor.execute("get_user_backlog", { "status" => "backlog" })

    assert_equal 1, result[:games].length
    assert_equal "backlog", result[:games].first[:status]
  end

  test "should apply limit to get_user_backlog" do
    @user.user_games.destroy_all

    # Create more games than the limit
    3.times do |i|
      game = Game.create!(title: "Test Game #{i}", platform: "PC", external_id: "test-#{1000 + i}")
      UserGame.create!(user: @user, game: game, status: "backlog")
    end

    # Test with limit parameter
    result = @executor.execute("get_user_backlog", { "limit" => 2 })

    assert_equal 2, result[:games].length
  end

  test "should default to limit of 50 for get_user_backlog" do
    @user.user_games.destroy_all

    # Create games
    10.times do |i|
      game = Game.create!(title: "Test Game #{i}", platform: "PC", external_id: "test-#{2000 + i}")
      UserGame.create!(user: @user, game: game, status: "backlog")
    end

    result = @executor.execute("get_user_backlog", {})

    # Should return all 10 since it's under the default limit
    assert_equal 10, result[:games].length
  end

  test "should return all required fields in get_user_backlog" do
    @user.user_games.destroy_all

    game = games(:one)
    user_game = UserGame.create!(
      user: @user,
      game: game,
      status: "playing",
      priority: 5,
      hours_played: 10.5,
      notes: "Great game"
    )

    result = @executor.execute("get_user_backlog", {})

    first_game = result[:games].first
    assert_equal user_game.id, first_game[:id]
    assert_equal game.id, first_game[:game_id]
    assert_equal game.title, first_game[:title]
    assert_equal "playing", first_game[:status]
    assert_equal 5, first_game[:priority]
    assert_equal 10.5, first_game[:hours_played]
    assert_equal "Great game", first_game[:notes]
    assert first_game.key?(:platform)
  end

  test "should execute update_game_status with string keys" do
    # Clear any existing user_games for this user to ensure clean test
    @user.user_games.destroy_all

    game = games(:one)
    user_game = UserGame.create!(user: @user, game: game, status: "backlog")

    # Use string keys like Anthropic API
    result = @executor.execute("update_game_status", {
      "user_game_id" => user_game.id,
      "status" => "playing"
    })

    assert result[:success]
    assert_equal "playing", result[:status]
    assert_equal user_game.id, result[:id]
    assert_equal game.id, result[:game_id]

    user_game.reload
    assert_equal "playing", user_game.status
  end

  test "should update priority in update_game_status" do
    @user.user_games.destroy_all

    game = games(:one)
    user_game = UserGame.create!(user: @user, game: game, status: "backlog", priority: 5)

    result = @executor.execute("update_game_status", {
      "user_game_id" => user_game.id,
      "priority" => 10
    })

    assert result[:success]
    assert_equal 10, result[:priority]

    user_game.reload
    assert_equal 10, user_game.priority
  end

  test "should update notes in update_game_status" do
    @user.user_games.destroy_all

    game = games(:one)
    user_game = UserGame.create!(user: @user, game: game, status: "playing")

    result = @executor.execute("update_game_status", {
      "user_game_id" => user_game.id,
      "notes" => "Amazing graphics!"
    })

    assert result[:success]
    assert_equal "Amazing graphics!", result[:notes]

    user_game.reload
    assert_equal "Amazing graphics!", user_game.notes
  end

  test "should update multiple fields in update_game_status" do
    @user.user_games.destroy_all

    game = games(:one)
    user_game = UserGame.create!(user: @user, game: game, status: "backlog", priority: 5)

    result = @executor.execute("update_game_status", {
      "user_game_id" => user_game.id,
      "status" => "completed",
      "priority" => 1,
      "notes" => "Best game ever!"
    })

    assert result[:success]
    assert_equal "completed", result[:status]
    assert_equal 1, result[:priority]
    assert_equal "Best game ever!", result[:notes]

    user_game.reload
    assert_equal "completed", user_game.status
    assert_equal 1, user_game.priority
    assert_equal "Best game ever!", user_game.notes
  end

  test "should handle update_game_status for non-existent user_game" do
    result = @executor.execute("update_game_status", {
      "user_game_id" => 99999,
      "status" => "completed"
    })

    assert_not result[:success]
    assert result[:error]
  end

  test "should enforce user scoping in update_game_status" do
    @user.user_games.destroy_all
    other_user = users(:two)

    game = games(:one)
    other_user_game = UserGame.create!(user: other_user, game: game, status: "backlog")

    # Try to update another user's game
    result = @executor.execute("update_game_status", {
      "user_game_id" => other_user_game.id,
      "status" => "playing"
    })

    assert_not result[:success]
    assert result[:error]

    # Verify the other user's game was not modified
    other_user_game.reload
    assert_equal "backlog", other_user_game.status
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
