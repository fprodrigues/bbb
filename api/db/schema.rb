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

ActiveRecord::Schema[7.1].define(version: 2026_07_07_010508) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "election_participants", force: :cascade do |t|
    t.bigint "election_id", null: false
    t.bigint "participant_id", null: false
    t.integer "final_votes", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["election_id", "participant_id"], name: "idx_election_participant_unique", unique: true
    t.index ["election_id"], name: "index_election_participants_on_election_id"
    t.index ["participant_id"], name: "index_election_participants_on_participant_id"
  end

  create_table "elections", force: :cascade do |t|
    t.string "status", default: "draft", null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_elections_on_status"
  end

  create_table "participants", force: :cascade do |t|
    t.string "name", null: false
    t.string "avatar_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_participants_on_name", unique: true
  end

  create_table "vote_snapshots", force: :cascade do |t|
    t.bigint "election_id", null: false
    t.bigint "participant_id", null: false
    t.integer "votes", default: 0, null: false
    t.datetime "hour", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["election_id", "participant_id", "hour"], name: "idx_vote_snapshots_unique", unique: true
    t.index ["election_id"], name: "index_vote_snapshots_on_election_id"
    t.index ["participant_id"], name: "index_vote_snapshots_on_participant_id"
  end

  add_foreign_key "election_participants", "elections"
  add_foreign_key "election_participants", "participants"
  add_foreign_key "vote_snapshots", "elections"
  add_foreign_key "vote_snapshots", "participants"
end
