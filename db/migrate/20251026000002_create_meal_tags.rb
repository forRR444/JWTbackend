# frozen_string_literal: true

class CreateMealTags < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_tags do |t|
      t.references :meal, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true
      t.timestamps
    end

    add_index :meal_tags, %i[meal_id tag_id], unique: true
  end
end
