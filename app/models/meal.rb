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

  # tagsゲッターをオーバーライドして文字列配列を返す
  def tags
    # 永続化されている場合はタグ名の配列を返す
    if persisted? || association(:tags).loaded?
      tag_names
    else
      # まだ保存されていない場合は関連付けを返す
      super
    end
  end

  # tagsをオーバーライドして文字列配列を受け取れるようにする
  def tags=(value)
    # 文字列配列が渡された場合
    if value.is_a?(Array) && (value.empty? || value.first.is_a?(String))
      self.tag_names = value
    else
      # Tagオブジェクトの配列が渡された場合は通常の関連付け
      super
    end
  end

  # タグ名の配列でタグを設定
  def tag_names=(names)
    # 配列に変換し、空白をトリム、空の値を除外、重複を削除
    cleaned_names = Array(names)
      .map { |name| name.to_s.strip }
      .reject(&:blank?)
      .uniq

    # 空の場合はクリア
    if cleaned_names.empty?
      meal_tags.clear
      return
    end

    tag_objects = Tag.find_or_create_by_names(cleaned_names)
    # 既存の関連を置き換え
    self.meal_tags.destroy_all
    tag_objects.each do |tag|
      meal_tags.build(tag: tag)
    end
  end

  # タグ名の配列を取得
  def tag_names
    # 関連付けから直接取得（無限ループ回避）
    if association(:tags).loaded?
      association(:tags).target.map(&:name)
    elsif persisted?
      Tag.joins(:meal_tags).where(meal_tags: { meal_id: id }).pluck(:name)
    else
      # 未保存の場合は空配列
      []
    end
  end

  # カンマ区切りのタグ文字列を設定
  def tags_text=(text)
    self.tag_names = text.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  # カンマ区切りのタグ文字列を取得
  def tags_text
    tag_names.join(",")
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
