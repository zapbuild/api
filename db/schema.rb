# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20140518182951) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_tokens", force: true do |t|
    t.integer  "client_id"
    t.integer  "refresh_token_id"
    t.string   "token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "access_tokens", ["expires_at"], name: "index_access_tokens_on_expires_at", using: :btree
  add_index "access_tokens", ["token"], name: "index_access_tokens_on_token", unique: true, using: :btree

  create_table "articles", force: true do |t|
    t.string   "doi",                                null: false
    t.text     "title",                              null: false
    t.integer  "journal_id"
    t.date     "publication_date"
    t.text     "abstract"
    t.float    "repeatability",        default: 0.0
    t.float    "materials",            default: 0.0
    t.float    "quality_of_stats",     default: 0.0
    t.float    "disclosure",           default: 0.0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "authors_denormalized"
  end

  add_index "articles", ["doi"], name: "index_articles_on_doi", unique: true, using: :btree
  add_index "articles", ["journal_id"], name: "index_articles_on_journal_id", using: :btree
  add_index "articles", ["publication_date"], name: "index_articles_on_publication_date", using: :btree

  create_table "clients", force: true do |t|
    t.string   "identifier"
    t.string   "secret"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "clients", ["identifier"], name: "index_clients_on_identifier", unique: true, using: :btree
  add_index "clients", ["name"], name: "index_clients_on_name", unique: true, using: :btree

  create_table "refresh_tokens", force: true do |t|
    t.integer  "client_id"
    t.string   "token"
    t.datetime "expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "refresh_tokens", ["token"], name: "index_refresh_tokens_on_token", unique: true, using: :btree

  create_table "studies", force: true do |t|
    t.text     "independent_variables"
    t.text     "dependent_variables"
    t.integer  "n"
    t.integer  "article_id"
    t.float    "power"
    t.text     "effect_size"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "studies", ["article_id"], name: "index_studies_on_article_id", using: :btree

  create_table "users", force: true do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.boolean  "admin"
    t.boolean  "curator"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

end
