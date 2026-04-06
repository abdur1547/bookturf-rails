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

ActiveRecord::Schema[8.1].define(version: 2026_04_03_111155) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "blacklisted_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "jti"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["jti"], name: "index_blacklisted_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_blacklisted_tokens_on_user_id"
  end

  create_table "password_reset_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "otp_code_digest", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.bigint "user_id", null: false
    t.index ["expires_at"], name: "index_password_reset_tokens_on_expires_at"
    t.index ["otp_code_digest"], name: "index_password_reset_tokens_on_otp_code_digest"
    t.index ["user_id"], name: "index_password_reset_tokens_on_user_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "crypted_token"
    t.datetime "exp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["crypted_token"], name: "index_refresh_tokens_on_crypted_token", unique: true
    t.index ["user_id"], name: "index_refresh_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", default: "", null: false
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "blacklisted_tokens", "users"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "refresh_tokens", "users"
end
