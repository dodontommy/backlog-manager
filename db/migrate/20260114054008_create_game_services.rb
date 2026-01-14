class CreateGameServices < ActiveRecord::Migration[8.1]
  def change
    create_table :game_services do |t|
      t.references :user, null: false, foreign_key: true
      t.string :service_name
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at

      t.timestamps
    end
  end
end
