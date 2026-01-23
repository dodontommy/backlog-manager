require 'omniauth'
require 'net/http'
require 'uri'
require 'json'

module OmniAuth
  module Strategies
    class SteamCustom
      include OmniAuth::Strategy

      option :name, 'steam_custom'
      option :api_key, nil

      # Step 1: Redirect to Steam login
      def request_phase
        realm = full_host
        return_to = callback_url
        
        params = {
          'openid.ns' => 'http://specs.openid.net/auth/2.0',
          'openid.mode' => 'checkid_setup',
          'openid.return_to' => return_to,
          'openid.realm' => realm,
          'openid.identity' => 'http://specs.openid.net/auth/2.0/identifier_select',
          'openid.claimed_id' => 'http://specs.openid.net/auth/2.0/identifier_select'
        }
        
        query_string = params.map { |k, v| "#{k}=#{CGI.escape(v)}" }.join('&')
        redirect "https://steamcommunity.com/openid/login?#{query_string}"
      end

      # Step 2: Handle callback from Steam
      def callback_phase
        return fail!(:invalid_credentials) unless validate_steam_response
        
        steam_id = extract_steam_id
        return fail!(:invalid_credentials) unless steam_id
        
        # Get user info from Steam API (without SSL verification in development)
        user_info = fetch_user_info(steam_id)
        
        @uid = steam_id
        @user_info = user_info
        
        super
      rescue => e
        fail!(:invalid_credentials, e)
      end

      uid { @uid }

      info do
        {
          'nickname' => @user_info['personaname'],
          'name' => @user_info['personaname'],
          'image' => @user_info['avatarfull'],
          'urls' => { 'Profile' => @user_info['profileurl'] }
        }
      end

      extra do
        { 'raw_info' => @user_info }
      end

      private

      def validate_steam_response
        # Simple validation - just check if we got the required params
        request.params['openid.claimed_id'] && 
        request.params['openid.claimed_id'].include?('steamcommunity.com')
      end

      def extract_steam_id
        claimed_id = request.params['openid.claimed_id']
        return nil unless claimed_id
        
        # Extract Steam ID from URL like: https://steamcommunity.com/openid/id/76561197986336107
        match = claimed_id.match(/\/id\/(\d+)/)
        match ? match[1] : nil
      end

      def fetch_user_info(steam_id)
        api_key = options.api_key || ENV['STEAM_API_KEY']
        return default_user_info(steam_id) unless api_key
        
        uri = URI("https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=#{api_key}&steamids=#{steam_id}")
        
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        # Disable SSL verification in development
        if defined?(Rails) && (Rails.env.development? || Rails.env.test?)
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.read_timeout = 10
        http.open_timeout = 5
        
        response = http.get(uri.request_uri)
        
        if response.code == '200'
          data = JSON.parse(response.body)
          player = data.dig('response', 'players', 0)
          return player if player
        end
        
        default_user_info(steam_id)
      rescue => e
        Rails.logger.error "Steam API error: #{e.message}" if defined?(Rails)
        default_user_info(steam_id)
      end

      def default_user_info(steam_id)
        {
          'steamid' => steam_id,
          'personaname' => "Steam User #{steam_id[-4..-1]}",
          'profileurl' => "https://steamcommunity.com/profiles/#{steam_id}",
          'avatar' => '',
          'avatarmedium' => '',
          'avatarfull' => ''
        }
      end
    end
  end
end
