# frozen_string_literal: true

# 月間カレンダー用の食事統計を提供

class MealCalendarService
  # @param user [User] 対象ユーザー
  # @param month_string [String] 対象月（YYYY-MM形式）
  def initialize(user, month_string)
    @user = user
    @month_string = month_string
  end

  # カレンダーデータを生成
  def call
    {
      month: @month_string,
      days: build_calendar_days
    }
  end

  private

  # 月の範囲(開始日・終了日)を計算
  def month_range
    year, month = @month_string.split("-").map(&:to_i)
    first = Date.new(year, month, 1)
    last = first.end_of_month
    [first, last]
  end

  # 月内の食事データを取得
  def fetch_meals
    first, last = month_range
    @user.meals.includes(:tags).between(first, last)
  end

  # 日付ごと集計データを生成
  def build_calendar_days
    meals = fetch_meals
    grouped = meals.group_by { |m| m.eaten_on.to_s }

    grouped.transform_values do |day_meals|
      {
        total: day_meals.size, # その日の食事件数
        by_type: count_by_type(day_meals) # タイプ別件数
      }
    end
  end

  # 食事タイプ(朝食など)別の件数をカウント
  def count_by_type(meals)
    meals.group_by(&:meal_type).transform_values(&:size)
  end
end
