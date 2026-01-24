class User < ApplicationRecord
  has_many :user_games, dependent: :destroy
  has_many :games, through: :user_games
  has_many :game_services, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :identities, dependent: :destroy
  has_many :chat_sessions, dependent: :destroy

  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :username, presence: true

  # Find or create user from OmniAuth auth hash
  def self.from_omniauth(auth_hash)
    provider = auth_hash["provider"]
    uid = auth_hash["uid"]
    email = auth_hash.dig("info", "email")

    # Steam doesn't provide email, so handle username differently
    if provider == "steam" || provider == "steam_custom"
      username = auth_hash.dig("info", "nickname") || auth_hash.dig("info", "name") || "steam_user_#{uid}"
      # For Steam, use a placeholder email or leave it nil
      email = nil unless email.present?
    else
      username = auth_hash.dig("info", "nickname") || auth_hash.dig("info", "name") || "user_#{uid}"
    end

    avatar_url = auth_hash.dig("info", "image")

    # Try to find user by provider/uid first
    user = find_by(provider: provider, uid: uid)

    # If not found and email exists, try to find by email
    user ||= find_by(email: email) if email.present?

    # Create new user if not found
    if user.nil?
      user = new(
        email: email,
        username: username,
        provider: provider,
        uid: uid,
        avatar_url: avatar_url
      )
      user.save!
    else
      # Update existing user with latest OAuth info
      user.update(
        provider: provider,
        uid: uid,
        avatar_url: avatar_url
      )
    end

    # Create or update identity
    Identity.find_or_create_from_omniauth(auth_hash, user)

    user
  end

  # Get Steam identity for this user
  def steam_identity
    identities.find_by(provider: "steam")
  end

  # Check if user has a connected Steam account
  def steam_connected?
    steam_identity.present?
  end

  # Get Steam ID if available
  def steam_id
    steam_identity&.steam_id
  end
end
