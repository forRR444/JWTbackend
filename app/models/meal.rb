class Meal < ApplicationRecord
  belongs_to :user
  has_many :meal_tags, dependent: :destroy
  has_many :tags, through: :meal_tags

  # 食事タイプ（朝食/昼食/夕食/間食/その他）
  MEAL_TYPES = %w[breakfast lunch dinner snack other].freeze

  # バリデーション設定(食事タイプ・内容・摂取日)
  validates :meal_type, inclusion: { in: MEAL_TYPES }
  validates :content, presence: true
  validates :eaten_on, presence: true

  # スコープ(ユーザー別・日付別・期間別)
  scope :for_user, ->(user) { where(user_id: user.id) }
  scope :on, ->(date) { where(eaten_on: date) }
  scope :between, ->(from, to) { where(eaten_on: from..to) }

  # タグ名の配列でタグを設定（tags_text互換メソッド）
  def tag_names=(names)
    # 既存のタグをクリア
    self.tags.clear

    # 新しいタグを設定
    return if names.blank?

    tag_objects = Tag.find_or_create_by_names(Array(names))
    self.tags = tag_objects
  end

  # タグ名の配列を取得（tags_text互換メソッド）
  def tag_names
    tags.pluck(:name)
  end

  # レスポンス用JSONを生成（タグを配列で含む）
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

    super(base_attributes.merge(options)).merge({ tags: tag_names })
  end
end
