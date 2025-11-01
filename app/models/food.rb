class Food < ApplicationRecord
  validates :food_code, presence: true
  validates :index_number, presence: true, uniqueness: true
  validates :name, presence: true

  # 食品名で検索するスコープ
  scope :search_by_name, ->(query) {
    where("name LIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  # 栄養素情報を持つもののみ
  scope :with_nutrition, -> {
    where.not(calories: nil).or(where.not(protein: nil))
  }
end
