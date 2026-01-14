class User < ApplicationRecord
  has_many :user_games, dependent: :destroy
  has_many :games, through: :user_games
  has_many :game_services, dependent: :destroy
  has_many :recommendations, dependent: :destroy
  has_many :identities, dependent: :destroy

  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :username, presence: true

  # Find or create user from OmniAuth auth hash
  def self.from_omniauth(auth_hash)
    provider = auth_hash["provider"]
    uid = auth_hash["uid"]
    email = auth_hash.dig("info", "email")
    username = auth_hash.dig("info", "nickname") || auth_hash.dig("info", "name") || "user_#{uid}"
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
end
