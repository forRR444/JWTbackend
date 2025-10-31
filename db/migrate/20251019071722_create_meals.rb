# frozen_string_literal: true

class CreateMeals < ActiveRecord::Migration[8.0]
  def change
    create_table :meals do |t|
      t.references :user, null: false, foreign_key: true
      t.string :meal_type, null: false, default: "other"
      t.text :content, null: false
      t.integer :calories
      t.integer :grams
      t.string :tags_text

      t.timestamps
    end

    add_index :meals, %i[user_id created_at]
  end
end
