ENV["RAILS_ENV"] ||= "test"
ENV["ANTHROPIC_API_KEY"] ||= "sk-ant-test-key-123"

require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"
require "webmock/minitest"

# Disable external HTTP requests in tests
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end
  end
end
