require "test_helper"

class RecommendationsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get recommendations_url
    assert_response :success
  end
end
