# 食事データのフィルタリングロジックを提供
# 日付、日付範囲、デフォルトのフィルタリングに対応
class MealFiltersService
  # @param user [User] フィルタ対象のユーザー
  def initialize(user, params)
    @user = user
    @params = params
  end

  # @return [ActiveRecord::Relation] フィルタ済みの食事データ
  def call
    case
    when single_date? then filter_by_date
    when date_range? then filter_by_range
    else default_filter
    end
  end

  private

  def single_date?
    @params[:date].present?
  end

  def date_range?
    @params[:from].present? && @params[:to].present?
  end

  # 特定の日付でフィルタ
  def filter_by_date
    date = parse_date(@params[:date])
    return @user.meals.none if date.nil?

    @user.meals.on(date).order(created_at: :desc)
  end

  # 日付範囲でフィルタ
  def filter_by_range
    from_date = parse_date(@params[:from])
    to_date = parse_date(@params[:to])

    return @user.meals.none if from_date.nil? || to_date.nil?
    return @user.meals.none if from_date > to_date

    @user.meals.between(from_date, to_date).order(created_at: :desc)
  end

  # デフォルトフィルタ（全件、新しい順）
  def default_filter
    @user.meals.order(created_at: :desc)
  end

  # 日付文字列を安全にパース
  def parse_date(date_string)
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end
end
