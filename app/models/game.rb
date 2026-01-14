class Game < ApplicationRecord
  has_many :user_games, dependent: :destroy
  has_many :users, through: :user_games
  has_many :recommendations, dependent: :destroy

  validates :title, presence: true
  validates :platform, presence: true
end
