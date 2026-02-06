class CreateChatSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :chat_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.jsonb :messages, default: [], null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :chat_sessions, :expires_at
  end
end
