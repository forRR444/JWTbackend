class Meal < ApplicationRecord
  belongs_to :user

  MEAL_TYPES = %w[breakfast lunch dinner snack other].freeze

  # enum 代替（文字列）: DBをシンプルに保つ
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :content, presence: true

  # タグは内部的にカンマ区切りで保存、外部APIは配列で返す
  def tags
    (self.tags_text || "").split(",").map(&:strip).reject(&:empty?)
  end

  def tags=(arr)
    self.tags_text = Array(arr).map(&:to_s).map(&:strip).reject(&:empty?).uniq.join(",")
  end

  def as_json(options = {})
    super({ only: [:id, :meal_type, :content, :calories, :grams, :created_at, :updated_at] }.merge(options)).merge({
      tags: tags
    })
  end
end
