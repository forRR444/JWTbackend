# frozen_string_literal: true

class AddEatenOnToMeals < ActiveRecord::Migration[8.0]
  def change
    add_column :meals, :eaten_on, :date, null: false, default: -> { "CURRENT_DATE" }
    add_index  :meals, %i[user_id eaten_on]
  end
end
