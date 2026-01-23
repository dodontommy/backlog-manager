class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :steam_id, format: { with: /\A\d{17}\z/, message: "must be a 17-digit Steam ID" },
            allow_nil: true, if: :steam_provider?
  validates :profile_visibility, inclusion: { in: %w[public private friends_only unknown] },
            allow_nil: true

  # Find or create identity from OmniAuth auth hash
  def self.find_or_create_from_omniauth(auth_hash, user)
    identity = find_or_initialize_by(provider: auth_hash["provider"], uid: auth_hash["uid"])
    identity.user = user
    identity.access_token = auth_hash.dig("credentials", "token")
    identity.refresh_token = auth_hash.dig("credentials", "refresh_token")
    identity.expires_at = Time.at(auth_hash.dig("credentials", "expires_at")) if auth_hash.dig("credentials", "expires_at")
    identity.extra_info = auth_hash.dig("extra") || {}

    # Store Steam ID for Steam provider
    if auth_hash["provider"] == "steam" || auth_hash["provider"] == "steam_custom"
      identity.steam_id = auth_hash["uid"]
    end

    identity.save!
    identity
  end

  def expired?
    expires_at && expires_at < Time.current
  end

  def steam_provider?
    provider == "steam" || provider == "steam_custom"
  end

  def public_profile?
    profile_visibility == "public"
  end

  def private_profile?
    profile_visibility == "private"
  end

  def profile_visibility_needs_check?
    return false unless steam_provider?
    profile_last_checked_at.nil? || profile_last_checked_at < 1.hour.ago
  end

  # Refresh Steam profile visibility from Steam Web API
  def refresh_steam_visibility!
    return unless steam_provider? && steam_id.present?

    service = GamePlatforms::SteamService.new
    visibility_data = service.fetch_player_summary(steam_id)

    if visibility_data
      self.profile_visibility = visibility_data[:visibility]
      self.profile_configured = visibility_data[:profile_configured]
      self.profile_last_checked_at = Time.current
      save!
    end

    visibility_data
  rescue => e
    Rails.logger.error "Failed to refresh Steam visibility for identity #{id}: #{e.message}"
    nil
  end
end
