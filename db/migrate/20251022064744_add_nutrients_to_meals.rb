# frozen_string_literal: true

class AddNutrientsToMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :meals, :protein, :decimal, precision: 8, scale: 1, comment: "たんぱく質 (g)"
    add_column :meals, :fat, :decimal, precision: 8, scale: 1, comment: "脂質 (g)"
    add_column :meals, :carbohydrate, :decimal, precision: 8, scale: 1, comment: "炭水化物 (g)"
  end
end
