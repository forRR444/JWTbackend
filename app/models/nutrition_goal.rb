class NutritionGoal < ApplicationRecord
  # リレーション
  belongs_to :user

  # バリデーション
  validates :start_date, presence: true
  validates :target_calories, numericality: { greater_than: 0, allow_nil: true }
  validates :target_protein, numericality: { greater_than: 0, allow_nil: true }
  validates :target_fat, numericality: { greater_than: 0, allow_nil: true }
  validates :target_carbohydrate, numericality: { greater_than: 0, allow_nil: true }

  # カスタムバリデーション: end_dateはstart_date以降であること
  validate :end_date_after_start_date

  # スコープ
  # 現在有効な目標（end_dateがnullまたは未来）
  scope :active, -> {
    where(end_date: nil).or(where("end_date >= ?", Date.today))
  }

  # 期間内の目標
  scope :within_period, ->(date) {
    where("start_date <= ?", date)
      .where("end_date IS NULL OR end_date >= ?", date)
  }

  # クラスメソッド
  # 指定日時点での有効な目標を取得
  def self.active_on(date = Date.today)
    within_period(date).order(start_date: :desc).first
  end

  # インスタンスメソッド
  # 目標が現在有効かどうか
  def active?
    start_date <= Date.today && (end_date.nil? || end_date >= Date.today)
  end

  # 目標を無効化（終了日を設定）
  def deactivate!(end_date = nil)
    # end_dateが指定されていない場合は、昨日または開始日の前日を使う
    end_date ||= [ Date.yesterday, start_date - 1.day ].max

    # start_dateより前の日付は設定できないので、start_dateと同じ日にする
    end_date = [ end_date, start_date ].max

    update!(end_date: end_date)
  end

  private

  def end_date_after_start_date
    return if end_date.blank? || start_date.blank?

    if end_date < start_date
      errors.add(:end_date, "は開始日以降の日付を指定してください")
    end
  end
end
