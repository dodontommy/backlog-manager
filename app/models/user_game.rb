class UserGame < ApplicationRecord
  belongs_to :user
  belongs_to :game

  STATUSES = %w[backlog playing completed abandoned wishlist].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :completion_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :priority, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }, allow_nil: true
end
