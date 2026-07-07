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

ActiveRecord::Schema[8.0].define(version: 2026_07_02_160001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "health_summaries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "chronotype"
    t.time "sleep_start_local"
    t.time "sleep_end_local"
    t.integer "avg_sleep_duration_minutes"
    t.float "routine_stability_index"
    t.integer "activity_level"
    t.time "peak_energy_start_local"
    t.time "peak_energy_end_local"
    t.integer "recovery_score"
    t.integer "source", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "effective_from"], name: "index_health_summaries_on_user_id_and_effective_from"
    t.index ["user_id"], name: "idx_one_active_health_summary_per_user", unique: true, where: "(effective_to IS NULL)"
    t.index ["user_id"], name: "index_health_summaries_on_user_id"
  end

  create_table "match_participants", force: :cascade do |t|
    t.bigint "match_id", null: false
    t.bigint "user_id", null: false
    t.integer "role", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["match_id", "user_id"], name: "index_match_participants_on_match_id_and_user_id", unique: true
    t.index ["match_id"], name: "index_match_participants_on_match_id"
    t.index ["user_id"], name: "index_match_participants_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.float "compatibility_score", null: false
    t.integer "status", default: 0, null: false
    t.datetime "accepted_at"
    t.datetime "rejected_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "preference_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "visual_embedding"
    t.jsonb "music_profile"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "sleep_together_importance", comment: "Likert 1-5: how important is sleeping together"
    t.integer "temperature_preference", comment: "enum: cool=0, warm=1, no_preference=2"
    t.integer "movement_preference", comment: "enum: very_little=0, moderate=1, a_lot=2, as_much_as_possible=3"
    t.integer "rhythm_importance", comment: "Likert 1-5: how important is shared daily rhythm"
    t.integer "self_chronotype", comment: "enum: morning=0, night=1, depends=2"
    t.index ["user_id"], name: "index_preference_profiles_on_user_id", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "display_name", null: false
    t.date "birth_date"
    t.string "gender"
    t.text "bio"
    t.string "city"
    t.string "photo_url_main"
    t.jsonb "photo_urls", default: [], null: false
    t.float "trust_score", default: 50.0, null: false
    t.boolean "spark_verified", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id", unique: true
  end

  create_table "spark_rewards", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "spark_id", null: false
    t.integer "reward_type", null: false
    t.integer "status", default: 0, null: false
    t.datetime "valid_until"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["spark_id"], name: "index_spark_rewards_on_spark_id"
    t.index ["user_id", "status"], name: "index_spark_rewards_on_user_id_and_status"
    t.index ["user_id"], name: "index_spark_rewards_on_user_id"
  end

  create_table "sparks", force: :cascade do |t|
    t.bigint "initiator_id", null: false
    t.bigint "partner_id"
    t.integer "status", default: 0, null: false
    t.string "session_code", null: false
    t.string "qr_token", null: false
    t.float "location_lat"
    t.float "location_lng"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.jsonb "initiator_answers"
    t.jsonb "partner_answers"
    t.float "compatibility_score"
    t.boolean "reward_issued_initiator", default: false, null: false
    t.boolean "reward_issued_partner", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["initiator_id"], name: "index_sparks_on_initiator_id"
    t.index ["partner_id"], name: "index_sparks_on_partner_id"
    t.index ["qr_token"], name: "index_sparks_on_qr_token", unique: true
    t.index ["session_code"], name: "index_sparks_on_session_code", unique: true
    t.index ["status"], name: "index_sparks_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "phone"
    t.integer "auth_provider", default: 0, null: false
    t.string "provider_uid"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "account_type", default: 0, null: false
    t.index ["account_type"], name: "index_users_on_account_type"
    t.index ["auth_provider", "provider_uid"], name: "index_users_on_auth_provider_and_provider_uid", unique: true, where: "(provider_uid IS NOT NULL)"
    t.index ["email"], name: "index_users_on_email", unique: true, where: "(email IS NOT NULL)"
    t.index ["phone"], name: "index_users_on_phone", unique: true, where: "(phone IS NOT NULL)"
  end

  add_foreign_key "health_summaries", "users"
  add_foreign_key "match_participants", "matches"
  add_foreign_key "match_participants", "users"
  add_foreign_key "preference_profiles", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "spark_rewards", "sparks"
  add_foreign_key "spark_rewards", "users"
  add_foreign_key "sparks", "users", column: "initiator_id"
  add_foreign_key "sparks", "users", column: "partner_id"
end
