# frozen_string_literal: true

class CreateNutritionGoals < ActiveRecord::Migration[8.0]
  def change
    create_table :nutrition_goals do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :target_calories, comment: "目標カロリー (kcal)"
      t.decimal :target_protein, precision: 8, scale: 1, comment: "目標たんぱく質 (g)"
      t.decimal :target_fat, precision: 8, scale: 1, comment: "目標脂質 (g)"
      t.decimal :target_carbohydrate, precision: 8, scale: 1, comment: "目標炭水化物 (g)"
      t.date :start_date, null: false, comment: "目標開始日"
      t.date :end_date, comment: "目標終了日（nullの場合は現在有効）"
      t.timestamps
    end

    add_index :nutrition_goals, %i[user_id start_date]
    add_index :nutrition_goals, %i[user_id end_date]
  end
end
