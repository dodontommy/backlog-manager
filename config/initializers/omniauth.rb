# Load custom strategies
require_relative "../../lib/omniauth/strategies/gog"

Rails.application.config.middleware.use OmniAuth::Builder do
  # Google OAuth2
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", nil),
    ENV.fetch("GOOGLE_CLIENT_SECRET", nil),
    {
      scope: "email,profile",
      prompt: "select_account",
      image_aspect_ratio: "square",
      image_size: 200
    }

  # Facebook OAuth
  provider :facebook,
    ENV.fetch("FACEBOOK_APP_ID", nil),
    ENV.fetch("FACEBOOK_APP_SECRET", nil),
    {
      scope: "email,public_profile",
      info_fields: "email,name,picture"
    }

  # Steam OAuth
  provider :steam,
    ENV.fetch("STEAM_API_KEY", nil)

  # GOG OAuth (custom strategy)
  provider :gog,
    ENV.fetch("GOG_CLIENT_ID", nil),
    ENV.fetch("GOG_CLIENT_SECRET", nil),
    {
      scope: "users.read"
    }
end

# Configure OmniAuth to handle errors gracefully
OmniAuth.config.on_failure = proc { |env|
  SessionsController.action(:failure).call(env)
}

# Allow HTTP in development (for local testing)
OmniAuth.config.allowed_request_methods = [ :post, :get ]
