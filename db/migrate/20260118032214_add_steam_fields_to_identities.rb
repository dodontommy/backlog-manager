class AddSteamFieldsToIdentities < ActiveRecord::Migration[8.1]
  def change
    add_column :identities, :steam_id, :string
    add_column :identities, :profile_visibility, :string, default: "unknown"
    add_column :identities, :profile_last_checked_at, :datetime
    add_column :identities, :profile_configured, :boolean, default: false

    add_index :identities, :steam_id, unique: true, where: "steam_id IS NOT NULL"
  end
end
