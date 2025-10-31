# frozen_string_literal: true

class MealTag < ApplicationRecord
  # リレーション
  belongs_to :meal
  belongs_to :tag

  # バリデーション
  validates :meal_id, uniqueness: { scope: :tag_id, message: "このタグは既に追加されています" }
end
