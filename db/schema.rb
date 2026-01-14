# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_01_14_054025) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "game_services", force: :cascade do |t|
    t.text "access_token"
    t.datetime "created_at", null: false
    t.text "refresh_token"
    t.string "service_name"
    t.datetime "token_expires_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_game_services_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "developer"
    t.string "external_id"
    t.string "genre"
    t.string "platform"
    t.string "publisher"
    t.date "release_date"
    t.string "title"
    t.datetime "updated_at", null: false
  end

  create_table "identities", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.json "extra_info"
    t.string "provider", null: false
    t.string "refresh_token"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["provider", "uid"], name: "index_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_identities_on_user_id"
  end

  create_table "recommendations", force: :cascade do |t|
    t.string "ai_model"
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.text "reason"
    t.decimal "score"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_recommendations_on_game_id"
    t.index ["user_id"], name: "index_recommendations_on_user_id"
  end

  create_table "user_games", force: :cascade do |t|
    t.integer "completion_percentage"
    t.datetime "created_at", null: false
    t.bigint "game_id", null: false
    t.decimal "hours_played"
    t.text "notes"
    t.integer "priority"
    t.string "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["game_id"], name: "index_user_games_on_game_id"
    t.index ["user_id"], name: "index_user_games_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.string "username"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  add_foreign_key "game_services", "users"
  add_foreign_key "identities", "users"
  add_foreign_key "recommendations", "games"
  add_foreign_key "recommendations", "users"
  add_foreign_key "user_games", "games"
  add_foreign_key "user_games", "users"
end
