class GameService < ApplicationRecord
  belongs_to :user

  SUPPORTED_SERVICES = %w[ steam gog epic ].freeze

  validates :service_name, presence: true, inclusion: { in: SUPPORTED_SERVICES }
  validates :service_name, uniqueness: { scope: :user_id }

  # Encrypt sensitive token data in production
  # encrypts :access_token, :refresh_token
end
