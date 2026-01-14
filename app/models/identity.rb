class Identity < ApplicationRecord
  belongs_to :user

  validates :provider, presence: true
  validates :uid, presence: true, uniqueness: { scope: :provider }

  # Find or create identity from OmniAuth auth hash
  def self.find_or_create_from_omniauth(auth_hash, user)
    identity = find_or_initialize_by(provider: auth_hash["provider"], uid: auth_hash["uid"])
    identity.user = user
    identity.access_token = auth_hash.dig("credentials", "token")
    identity.refresh_token = auth_hash.dig("credentials", "refresh_token")
    identity.expires_at = Time.at(auth_hash.dig("credentials", "expires_at")) if auth_hash.dig("credentials", "expires_at")
    identity.extra_info = auth_hash.dig("extra") || {}
    identity.save!
    identity
  end

  def expired?
    expires_at && expires_at < Time.current
  end
end
