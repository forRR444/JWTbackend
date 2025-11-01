class UserFood < ApplicationRecord
  # リレーション
  belongs_to :user

  # バリデーション
  validates :name, presence: true, length: { maximum: 100 }
  validates :calories, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :protein, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :fat, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :carbohydrate, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validates :default_grams, numericality: { greater_than: 0, allow_nil: true }

  # スコープ
  scope :search_by_name, ->(query) {
    where("name ILIKE ?", "%#{sanitize_sql_like(query)}%") if query.present?
  }

  # インスタンスメソッド
  # 栄養情報が設定されているか
  def has_nutrition_info?
    calories.present? || protein.present? || fat.present? || carbohydrate.present?
  end

  # JSON形式で返す
  def as_search_result
    {
      id: id,
      name: name,
      calories: calories,
      protein: protein,
      fat: fat,
      carbohydrate: carbohydrate,
      source: "custom" # ユーザーカスタム食品であることを示す
    }
  end
end
