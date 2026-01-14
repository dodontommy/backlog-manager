require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Gog < OmniAuth::Strategies::OAuth2
      option :name, "gog"

      option :client_options, {
        site: "https://auth.gog.com",
        authorize_url: "/auth",
        token_url: "/token"
      }

      option :authorize_params, {
        response_type: "code"
      }

      uid { raw_info["user_id"] }

      info do
        {
          email: raw_info["email"],
          name: raw_info["username"],
          nickname: raw_info["username"],
          image: raw_info["avatar"]
        }
      end

      extra do
        {
          raw_info: raw_info
        }
      end

      def raw_info
        @raw_info ||= access_token.get("/users/current").parsed
      rescue => e
        Rails.logger.error "GOG API error: #{e.message}"
        {}
      end

      def callback_url
        full_host + script_name + callback_path
      end
    end
  end
end
