# frozen_string_literal: true

class CreateFoods < ActiveRecord::Migration[8.0]
  def change
    create_table :foods do |t|
      t.string :food_code, null: false, comment: "食品番号 (例: 01)"
      t.string :index_number, null: false, comment: "索引番号 (例: 01001)"
      t.string :name, null: false, comment: "食品名"
      t.decimal :calories, precision: 8, scale: 1, comment: "エネルギー (kcal/100g)"
      t.decimal :protein, precision: 8, scale: 1, comment: "たんぱく質 (g/100g)"
      t.decimal :fat, precision: 8, scale: 1, comment: "脂質 (g/100g)"
      t.decimal :carbohydrate, precision: 8, scale: 1, comment: "炭水化物 (g/100g)"

      t.timestamps
    end

    add_index :foods, :name
    add_index :foods, :index_number, unique: true
  end
end
