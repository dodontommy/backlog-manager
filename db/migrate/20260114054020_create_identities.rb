class CreateIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :access_token
      t.string :refresh_token
      t.datetime :expires_at
      t.json :extra_info

      t.timestamps
    end

    add_index :identities, [ :provider, :uid ], unique: true
  end
end
