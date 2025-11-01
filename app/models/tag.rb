class Tag < ApplicationRecord
  # バリデーション
  validates :name, presence: true, uniqueness: true, length: { maximum: 20 }

  # リレーション
  has_many :meal_tags, dependent: :destroy
  has_many :meals, through: :meal_tags

  # スコープ
  scope :popular, ->(limit = 10) {
    joins(:meal_tags)
      .group(:id)
      .order("COUNT(meal_tags.id) DESC")
      .limit(limit)
  }

  # クラスメソッド
  # タグ名の配列からTagレコードを取得または作成
  def self.find_or_create_by_names(tag_names)
    tag_names.map do |name|
      find_or_create_by!(name: name.strip)
    end
  end
end
