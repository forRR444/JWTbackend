# frozen_string_literal: true

class Food < ApplicationRecord
  # 検索食品データのバリデーション設定(食品コード・インデックス番号・食品名)
  validates :food_code, presence: true
  validates :index_number, presence: true, uniqueness: true
  validates :name, presence: true

  # 食品名で部分一致検索
  scope :search_by_name, lambda { |query|
    where("name LIKE ?", "%#{sanitize_sql_like(query)}%")
  }

  # 栄養情報が存在する食品を取得
  scope :with_nutrition, lambda {
    where.not(calories: nil).or(where.not(protein: nil))
  }
end
