class CreateRecommendations < ActiveRecord::Migration[8.1]
  def change
    create_table :recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.decimal :score
      t.text :reason
      t.string :ai_model

      t.timestamps
    end
  end
end
