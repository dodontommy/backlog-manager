class CreateUserGames < ActiveRecord::Migration[8.1]
  def change
    create_table :user_games do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.string :status
      t.decimal :hours_played
      t.integer :completion_percentage
      t.integer :priority
      t.text :notes

      t.timestamps
    end
  end
end
