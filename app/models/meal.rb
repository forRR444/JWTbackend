class Meal < ApplicationRecord
  belongs_to :user

  # 食事の種類（朝食/昼食/夕食/間食/その他）
  MEAL_TYPES = %w[breakfast lunch dinner snack other].freeze

  # バリデーション
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :content, presence: true
  validates :eaten_on, presence: true

  # スコープ
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :on, ->(date) { where(eaten_on: date) }
  scope :between, ->(from, to) { where(eaten_on: from..to) }

  # タグアクセサー（DBにはカンマ区切りで保存、外部APIには配列で返す）
  def tags
    parse_tags_from_text(tags_text)
  end

  def tags=(arr)
    self.tags_text = build_tags_text(arr)
  end

  # JSON出力時のカスタマイズ
  def as_json(options = {})
    base_attributes = {
      only: [
        :id,
        :meal_type,
        :content,
        :calories,
        :grams,
        :protein,
        :fat,
        :carbohydrate,
        :eaten_on,
        :created_at,
        :updated_at
      ]
    }

    super(base_attributes.merge(options)).merge({ tags: tags })
  end

  private

  # タグテキストから配列を生成
  def parse_tags_from_text(text)
    return [] if text.blank?
    text.split(",").map(&:strip).reject(&:empty?)
  end

  # 配列からタグテキストを生成
  def build_tags_text(arr)
    Array(arr)
      .map(&:to_s)
      .map(&:strip)
      .reject(&:empty?)
      .uniq
      .join(",")
  end
end
