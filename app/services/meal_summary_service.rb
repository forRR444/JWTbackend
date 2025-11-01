# 食事データのサマリー（タイプ別グループ化）を提供
class MealSummaryService
  MEAL_TYPES = %w[breakfast lunch dinner snack other].freeze

  # @param user [User] 対象ユーザー
  def initialize(user, params)
    @user = user
    @params = params
  end

  # サマリーを生成
  def call
    meals = fetch_meals
    {
      range: build_range_info,
      groups: group_by_type(meals)
    }
  end

  private

  # 食事データを取得
  def fetch_meals
    MealFiltersService.new(@user, @params).call
  end

  # 日付範囲情報を構築
  def build_range_info
    if @params[:date].present?
      { date: @params[:date] }
    elsif @params[:from].present? && @params[:to].present?
      { from: @params[:from], to: @params[:to] }
    else
      { date: nil, from: nil, to: nil }
    end
  end

  # 食事タイプ別にグループ化
  def group_by_type(meals)
    grouped = meals.group_by(&:meal_type)

    MEAL_TYPES.each_with_object({}) do |type, hash|
      hash[type] = grouped[type] || []
    end
  end
end
