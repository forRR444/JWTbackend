# frozen_string_literal: true

class AddNutritionGoalsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :target_calories, :integer, comment: "目標カロリー (kcal)"
    add_column :users, :target_protein, :decimal, precision: 8, scale: 1, comment: "目標たんぱく質 (g)"
    add_column :users, :target_fat, :decimal, precision: 8, scale: 1, comment: "目標脂質 (g)"
    add_column :users, :target_carbohydrate, :decimal, precision: 8, scale: 1, comment: "目標炭水化物 (g)"
  end
end
