# 食事タイプ別グループ化を生成するサービスクラス
class MealSummaryService
  MEAL_TYPES = %w[breakfast lunch dinner snack other].freeze

  # @param user [User] 対象ユーザー
  # @param params [ActionController::Parameters] フィルタリング用パラメータ
  def initialize(user, params)
    @user = user
    @params = params
  end

  # @return [Hash] 食事タイプ別グループ化データ
  def call
    meals = fetch_meals
    {
      range: build_range_info,
      groups: group_by_type(meals)
    }
  end

  private
    # フィルタ済み食事データを取得
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
    # 各食事タイプ（朝食など）ごとに配列で格納
    def group_by_type(meals)
      grouped = meals.group_by(&:meal_type)

      MEAL_TYPES.each_with_object({}) do |type, hash|
        hash[type] = grouped[type] || []
      end
    end
end
