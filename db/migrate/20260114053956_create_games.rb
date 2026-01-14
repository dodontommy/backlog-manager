class CreateGames < ActiveRecord::Migration[8.1]
  def change
    create_table :games do |t|
      t.string :title
      t.text :description
      t.string :platform
      t.string :external_id
      t.date :release_date
      t.string :genre
      t.string :developer
      t.string :publisher

      t.timestamps
    end
  end
end
