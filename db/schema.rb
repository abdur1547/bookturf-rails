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

ActiveRecord::Schema[8.1].define(version: 2026_04_10_100507) do
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

  create_table "permissions", force: :cascade do |t|
    t.string "action", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.string "resource", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_permissions_on_name", unique: true
    t.index ["resource", "action"], name: "index_permissions_on_resource_and_action", unique: true
    t.index ["resource"], name: "index_permissions_on_resource"
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

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_custom", default: false, null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["is_custom"], name: "index_roles_on_is_custom"
    t.index ["name"], name: "index_roles_on_name", unique: true
    t.index ["slug"], name: "index_roles_on_slug", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "user_roles", force: :cascade do |t|
    t.datetime "assigned_at", null: false
    t.bigint "assigned_by_id"
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["assigned_by_id"], name: "index_user_roles_on_assigned_by_id"
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.string "first_name", null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_global_admin", default: false, null: false
    t.string "last_name", null: false
    t.string "password_digest", null: false
    t.string "phone_number"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_active"], name: "index_users_on_is_active"
    t.index ["is_global_admin"], name: "index_users_on_is_global_admin"
    t.index ["phone_number"], name: "index_users_on_phone_number"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "venue_operating_hours", force: :cascade do |t|
    t.time "closes_at", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week", null: false
    t.boolean "is_closed", default: false, null: false
    t.time "opens_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["venue_id", "day_of_week"], name: "index_venue_operating_hours_on_venue_id_and_day_of_week", unique: true
    t.index ["venue_id"], name: "index_venue_operating_hours_on_venue_id"
    t.check_constraint "day_of_week >= 0 AND day_of_week <= 6", name: "valid_day_of_week"
  end

  create_table "venue_settings", force: :cascade do |t|
    t.integer "advance_booking_days", default: 30
    t.integer "cancellation_hours"
    t.datetime "created_at", null: false
    t.string "currency", default: "PKR"
    t.integer "maximum_slot_duration", default: 180, null: false
    t.integer "minimum_slot_duration", default: 60, null: false
    t.boolean "requires_approval", default: false, null: false
    t.integer "slot_interval", default: 30, null: false
    t.string "timezone", default: "Asia/Karachi", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["venue_id"], name: "index_venue_settings_on_venue_id", unique: true
    t.check_constraint "maximum_slot_duration >= minimum_slot_duration", name: "maximum_greater_than_minimum"
    t.check_constraint "minimum_slot_duration > 0", name: "minimum_slot_duration_positive"
    t.check_constraint "slot_interval > 0", name: "slot_interval_positive"
  end

  create_table "venue_users", force: :cascade do |t|
    t.bigint "added_by_id"
    t.datetime "created_at", null: false
    t.datetime "joined_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "venue_id", null: false
    t.index ["added_by_id"], name: "index_venue_users_on_added_by_id"
    t.index ["user_id"], name: "index_venue_users_on_user_id"
    t.index ["venue_id", "user_id"], name: "index_venue_users_on_venue_id_and_user_id", unique: true
    t.index ["venue_id"], name: "index_venue_users_on_venue_id"
  end

  create_table "venues", force: :cascade do |t|
    t.text "address", null: false
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "email"
    t.boolean "is_active", default: true, null: false
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.string "phone_number"
    t.string "postal_code"
    t.string "slug", null: false
    t.string "state"
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_venues_on_city"
    t.index ["country"], name: "index_venues_on_country"
    t.index ["is_active"], name: "index_venues_on_is_active"
    t.index ["owner_id"], name: "index_venues_on_owner_id"
    t.index ["slug"], name: "index_venues_on_slug", unique: true
    t.index ["state"], name: "index_venues_on_state"
  end

  add_foreign_key "blacklisted_tokens", "users"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_roles", "users", column: "assigned_by_id"
  add_foreign_key "venue_operating_hours", "venues"
  add_foreign_key "venue_settings", "venues"
  add_foreign_key "venue_users", "users"
  add_foreign_key "venue_users", "users", column: "added_by_id"
  add_foreign_key "venue_users", "venues"
  add_foreign_key "venues", "users", column: "owner_id"
end
