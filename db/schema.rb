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

ActiveRecord::Schema.define(version: 2018_05_23_205303) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "certificate_authorities", force: :cascade do |t|
    t.string "key", null: false
    t.string "dn", null: false
    t.string "crl_http_url"
    t.datetime "valid_not_before", null: false
    t.datetime "valid_not_after", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ocsp_http_url"
    t.index ["key"], name: "index_certificate_authorities_on_key", unique: true
  end

  create_table "certificate_revocations", force: :cascade do |t|
    t.bigint "certificate_authority_id", null: false
    t.string "serial", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["certificate_authority_id", "serial"], name: "index_certificate_revocations_on_cert_auth_id_and_serial", unique: true
  end

  create_table "piv_cacs", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "dn_signature", null: false
    t.index ["dn_signature"], name: "index_piv_cacs_on_dn_signature", unique: true
    t.index ["uuid"], name: "index_piv_cacs_on_uuid", unique: true
  end

  create_table "unrecognized_certificate_authorities", force: :cascade do |t|
    t.string "key", null: false
    t.string "dn", null: false
    t.string "crl_http_url"
    t.string "ocsp_url"
    t.string "ca_issuer_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_unrecognized_certificate_authorities_on_key", unique: true
  end

  add_foreign_key "certificate_revocations", "certificate_authorities"
end
