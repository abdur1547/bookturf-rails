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

ActiveRecord::Schema[8.1].define(version: 2026_04_29_095634) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.bigint "owner_id"
    t.string "owner_type"
    t.text "parameters"
    t.bigint "recipient_id"
    t.string "recipient_type"
    t.bigint "trackable_id"
    t.string "trackable_type"
    t.datetime "updated_at", null: false
    t.index ["owner_type", "owner_id"], name: "index_activities_on_owner"
    t.index ["recipient_type", "recipient_id"], name: "index_activities_on_recipient"
    t.index ["trackable_type", "trackable_id"], name: "index_activities_on_trackable"
  end

  create_table "blacklisted_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "exp", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "jti"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["jti"], name: "index_blacklisted_tokens_on_jti", unique: true
    t.index ["user_id"], name: "index_blacklisted_tokens_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.string "booking_number", null: false
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.bigint "cancelled_by_id"
    t.datetime "checked_in_at"
    t.bigint "checked_in_by_id"
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "created_by_role"
    t.boolean "deferred_link_claimed", default: false, null: false
    t.integer "duration_minutes", null: false
    t.datetime "end_time", null: false
    t.text "notes"
    t.decimal "paid_amount", precision: 10, scale: 2, default: "0.0"
    t.string "payment_method"
    t.string "payment_status", default: "pending"
    t.decimal "price_at_booking", precision: 10, scale: 2
    t.string "share_token"
    t.datetime "start_time", null: false
    t.string "status", default: "confirmed", null: false
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "venue_id", null: false
    t.string "walk_in_name"
    t.index ["booking_number"], name: "index_bookings_on_booking_number", unique: true
    t.index ["cancelled_by_id"], name: "index_bookings_on_cancelled_by_id"
    t.index ["checked_in_by_id"], name: "index_bookings_on_checked_in_by_id"
    t.index ["court_id", "start_time", "end_time"], name: "index_bookings_on_court_id_and_start_time_and_end_time"
    t.index ["court_id"], name: "index_bookings_on_court_id"
    t.index ["created_by_id"], name: "index_bookings_on_created_by_id"
    t.index ["share_token"], name: "index_bookings_on_share_token", unique: true
    t.index ["start_time", "end_time"], name: "index_bookings_on_start_time_and_end_time"
    t.index ["status"], name: "index_bookings_on_status"
    t.index ["user_id"], name: "index_bookings_on_user_id"
    t.index ["venue_id", "start_time"], name: "index_bookings_on_venue_id_and_start_time"
    t.index ["venue_id"], name: "index_bookings_on_venue_id"
    t.check_constraint "duration_minutes > 0", name: "positive_duration"
    t.check_constraint "end_time > start_time", name: "end_time_after_start_time"
    t.check_constraint "paid_amount <= total_amount", name: "paid_not_exceeding_total"
    t.check_constraint "paid_amount >= 0::numeric", name: "non_negative_paid_amount"
  end

  create_table "court_closures", force: :cascade do |t|
    t.bigint "court_id", null: false
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.datetime "end_time", null: false
    t.datetime "start_time", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["court_id", "start_time", "end_time"], name: "index_court_closures_on_court_id_and_start_time_and_end_time"
    t.index ["court_id"], name: "index_court_closures_on_court_id"
    t.index ["created_by_id"], name: "index_court_closures_on_created_by_id"
    t.index ["start_time", "end_time"], name: "index_court_closures_on_start_time_and_end_time"
    t.index ["venue_id", "start_time"], name: "index_court_closures_on_venue_id_and_start_time"
    t.index ["venue_id"], name: "index_court_closures_on_venue_id"
    t.check_constraint "end_time > start_time", name: "closure_end_after_start"
  end

  create_table "court_types", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_court_types_on_name", unique: true
    t.index ["slug"], name: "index_court_types_on_slug", unique: true
  end

  create_table "courts", force: :cascade do |t|
    t.bigint "court_type_id", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "display_order", default: 0, null: false
    t.jsonb "images_data"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.string "qr_code_url"
    t.boolean "requires_approval", default: false, null: false
    t.integer "slot_interval", default: 60, null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["court_type_id"], name: "index_courts_on_court_type_id"
    t.index ["is_active"], name: "index_courts_on_is_active"
    t.index ["venue_id", "name"], name: "index_courts_on_venue_id_and_name", unique: true
    t.index ["venue_id"], name: "index_courts_on_venue_id"
    t.check_constraint "slot_interval > 0", name: "court_slot_interval_positive"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action_url"
    t.bigint "booking_id"
    t.datetime "created_at", null: false
    t.boolean "is_read", default: false, null: false
    t.text "message", null: false
    t.string "notification_type", null: false
    t.string "priority", default: "normal", null: false
    t.datetime "read_at"
    t.datetime "sent_at"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.bigint "venue_id"
    t.index ["booking_id"], name: "index_notifications_on_booking_id"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["priority"], name: "index_notifications_on_priority"
    t.index ["user_id", "created_at"], name: "index_notifications_on_user_id_and_created_at"
    t.index ["user_id", "is_read"], name: "index_notifications_on_user_id_and_is_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
    t.index ["venue_id"], name: "index_notifications_on_venue_id"
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

  create_table "pricing_rules", force: :cascade do |t|
    t.bigint "court_type_id", null: false
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.date "end_date"
    t.time "end_time"
    t.boolean "is_active", default: true, null: false
    t.string "name", null: false
    t.decimal "price_per_hour", precision: 10, scale: 2, null: false
    t.integer "priority", default: 0, null: false
    t.date "start_date"
    t.time "start_time"
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["court_type_id"], name: "index_pricing_rules_on_court_type_id"
    t.index ["is_active"], name: "index_pricing_rules_on_is_active"
    t.index ["priority"], name: "index_pricing_rules_on_priority"
    t.index ["venue_id", "court_type_id"], name: "index_pricing_rules_on_venue_id_and_court_type_id"
    t.index ["venue_id"], name: "index_pricing_rules_on_venue_id"
    t.check_constraint "price_per_hour >= 0::numeric", name: "price_non_negative"
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
    t.string "full_name", null: false
    t.boolean "is_active", default: true, null: false
    t.boolean "is_global_admin", default: false, null: false
    t.string "password_digest", null: false
    t.string "phone_number"
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["is_active"], name: "index_users_on_is_active"
    t.index ["is_global_admin"], name: "index_users_on_is_global_admin"
    t.index ["phone_number"], name: "index_users_on_phone_number", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
  end

  create_table "venue_closures", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.datetime "end_time", null: false
    t.datetime "start_time", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["created_by_id"], name: "index_venue_closures_on_created_by_id"
    t.index ["start_time", "end_time"], name: "index_venue_closures_on_start_time_and_end_time"
    t.index ["venue_id", "start_time", "end_time"], name: "index_venue_closures_on_venue_id_and_start_time_and_end_time"
    t.index ["venue_id", "start_time"], name: "index_venue_closures_on_venue_id_and_start_time"
    t.index ["venue_id"], name: "index_venue_closures_on_venue_id"
    t.check_constraint "end_time > start_time", name: "closure_end_after_start"
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
    t.string "currency", default: "PKR", null: false
    t.text "description"
    t.string "email"
    t.boolean "is_active", default: true, null: false
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.string "phone_number"
    t.string "postal_code"
    t.string "qr_code_url"
    t.string "slug", null: false
    t.string "state"
    t.string "timezone", default: "Asia/Karachi", null: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_venues_on_city"
    t.index ["country"], name: "index_venues_on_country"
    t.index ["is_active"], name: "index_venues_on_is_active"
    t.index ["owner_id"], name: "index_venues_on_owner_id"
    t.index ["slug"], name: "index_venues_on_slug", unique: true
    t.index ["state"], name: "index_venues_on_state"
  end

  add_foreign_key "blacklisted_tokens", "users"
  add_foreign_key "bookings", "courts"
  add_foreign_key "bookings", "users"
  add_foreign_key "bookings", "users", column: "cancelled_by_id"
  add_foreign_key "bookings", "users", column: "checked_in_by_id"
  add_foreign_key "bookings", "users", column: "created_by_id"
  add_foreign_key "bookings", "venues"
  add_foreign_key "court_closures", "courts"
  add_foreign_key "court_closures", "users", column: "created_by_id"
  add_foreign_key "court_closures", "venues"
  add_foreign_key "courts", "court_types"
  add_foreign_key "courts", "venues"
  add_foreign_key "notifications", "bookings"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "venues"
  add_foreign_key "password_reset_tokens", "users"
  add_foreign_key "pricing_rules", "court_types"
  add_foreign_key "pricing_rules", "venues"
  add_foreign_key "refresh_tokens", "users"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_roles", "users", column: "assigned_by_id"
  add_foreign_key "venue_closures", "users", column: "created_by_id"
  add_foreign_key "venue_closures", "venues"
  add_foreign_key "venue_operating_hours", "venues"
  add_foreign_key "venue_users", "users"
  add_foreign_key "venue_users", "users", column: "added_by_id"
  add_foreign_key "venue_users", "venues"
  add_foreign_key "venues", "users", column: "owner_id"
end
