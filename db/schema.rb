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

ActiveRecord::Schema[8.0].define(version: 2025_10_22_101809) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "foods", force: :cascade do |t|
    t.string "food_code", null: false, comment: "食品番号 (例: 01)"
    t.string "index_number", null: false, comment: "索引番号 (例: 01001)"
    t.string "name", null: false, comment: "食品名"
    t.decimal "calories", precision: 8, scale: 1, comment: "エネルギー (kcal/100g)"
    t.decimal "protein", precision: 8, scale: 1, comment: "たんぱく質 (g/100g)"
    t.decimal "fat", precision: 8, scale: 1, comment: "脂質 (g/100g)"
    t.decimal "carbohydrate", precision: 8, scale: 1, comment: "炭水化物 (g/100g)"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["index_number"], name: "index_foods_on_index_number", unique: true
    t.index ["name"], name: "index_foods_on_name"
  end

  create_table "jobs", force: :cascade do |t|
    t.string "title"
    t.string "category"
    t.integer "salary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "meals", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "meal_type", default: "other", null: false
    t.text "content", null: false
    t.integer "calories"
    t.integer "grams"
    t.string "tags_text"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "eaten_on", default: -> { "CURRENT_DATE" }, null: false
    t.decimal "protein", precision: 8, scale: 1, comment: "たんぱく質 (g)"
    t.decimal "fat", precision: 8, scale: 1, comment: "脂質 (g)"
    t.decimal "carbohydrate", precision: 8, scale: 1, comment: "炭水化物 (g)"
    t.index ["user_id", "created_at"], name: "index_meals_on_user_id_and_created_at"
    t.index ["user_id", "eaten_on"], name: "index_meals_on_user_id_and_eaten_on"
    t.index ["user_id"], name: "index_meals_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.boolean "activated", default: false, null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "refresh_jti"
    t.integer "target_calories", comment: "目標カロリー (kcal)"
    t.decimal "target_protein", precision: 8, scale: 1, comment: "目標たんぱく質 (g)"
    t.decimal "target_fat", precision: 8, scale: 1, comment: "目標脂質 (g)"
    t.decimal "target_carbohydrate", precision: 8, scale: 1, comment: "目標炭水化物 (g)"
  end

  add_foreign_key "meals", "users"
end
