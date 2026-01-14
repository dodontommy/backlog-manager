class Recommendation < ApplicationRecord
  belongs_to :user
  belongs_to :game

  validates :score, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 }
  validates :reason, presence: true
end
