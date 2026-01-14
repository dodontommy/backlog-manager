require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get games_url
    assert_response :success
  end

  test "should get show" do
    # Create a game fixture to test the show action
    game = games(:one)
    get game_url(game)
    assert_response :success
  end
end
