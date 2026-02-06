class AddRatingToUserGames < ActiveRecord::Migration[8.1]
  def change
    add_column :user_games, :rating, :integer
  end
end
