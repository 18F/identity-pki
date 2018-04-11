# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20180410124445) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificate_revocations", force: :cascade do |t|
    t.bigint "certificate_id", null: false
    t.string "serial", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_id", "serial"], name: "index_certificate_revocations_on_certificate_id_and_serial", unique: true
  end

  create_table "certificates", force: :cascade do |t|
    t.string "key", null: false
    t.string "dn", null: false
    t.string "crl_http_url"
    t.datetime "valid_not_before", null: false
    t.datetime "valid_not_after", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_certificates_on_key", unique: true
  end

  add_foreign_key "certificate_revocations", "certificates"
end
