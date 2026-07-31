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

ActiveRecord::Schema[8.1].define(version: 2026_07_31_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "attendees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_attendees_on_lower_email", unique: true
  end

  create_table "registrations", force: :cascade do |t|
    t.bigint "attendee_id", null: false
    t.datetime "cancelled_at"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "hold_expires_at"
    t.bigint "session_id", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["attendee_id", "session_id"], name: "index_registrations_on_active_attendee_session", unique: true, where: "((status)::text = ANY ((ARRAY['held'::character varying, 'confirmed'::character varying, 'waitlisted'::character varying])::text[]))"
    t.index ["attendee_id"], name: "index_registrations_on_attendee_id"
    t.index ["session_id"], name: "index_registrations_on_session_id"
    t.index ["status"], name: "index_registrations_on_status"
  end

  create_table "sessions", force: :cascade do |t|
    t.text "cancellation_reason"
    t.datetime "cancelled_at"
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at", null: false
    t.datetime "starts_at", null: false
    t.string "status", default: "scheduled", null: false
    t.datetime "updated_at", null: false
    t.bigint "workshop_id", null: false
    t.index ["starts_at"], name: "index_sessions_on_starts_at"
    t.index ["status"], name: "index_sessions_on_status"
    t.index ["workshop_id"], name: "index_sessions_on_workshop_id"
  end

  create_table "workshops", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "title", null: false
    t.string "topic", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_workshops_on_active"
    t.index ["topic"], name: "index_workshops_on_topic"
  end

  add_foreign_key "registrations", "attendees"
  add_foreign_key "registrations", "sessions"
  add_foreign_key "sessions", "workshops"
end
