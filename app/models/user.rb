class User < ApplicationRecord
  has_many :user_games, dependent: :destroy
  has_many :games, through: :user_games
  has_many :game_services, dependent: :destroy
  has_many :recommendations, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true
end
