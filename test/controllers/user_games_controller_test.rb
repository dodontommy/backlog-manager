require "test_helper"

class UserGamesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get user_games_url
    assert_response :success
  end
end
