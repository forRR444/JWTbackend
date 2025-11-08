# frozen_string_literal: true

# 食事データのフィルタリングを担当するサービスクラス
# 指定日・日付範囲・デフォルト（全件）で絞り込みを行う

class MealFiltersService
  # @param user [User] ログインユーザー
  # @param params [ActionController::Parameters] フィルタリング用パラメータ
  def initialize(user, params)
    @user = user
    @params = params
  end

  # @return [ActiveRecord::Relation] フィルタ済みの食事データ
  def call
    if single_date?
      filter_by_date # 単一日指定
    elsif date_range?
      filter_by_range # 日付範囲指定
    else
      default_filter # 指定なし（全件）
    end
  end

  private

  # 単一日フィルタか？
  def single_date?
    @params[:date].present?
  end

  # 日付範囲フィルタか？
  def date_range?
    @params[:from].present? && @params[:to].present?
  end

  # 単一日で絞り込み
  def filter_by_date
    date = parse_date(@params[:date])
    return @user.meals.none if date.nil?

    @user.meals.includes(:tags).on(date).order(created_at: :desc)
  end

  # 日付範囲で絞り込み
  def filter_by_range
    from_date = parse_date(@params[:from])
    to_date = parse_date(@params[:to])

    return @user.meals.none if from_date.nil? || to_date.nil?
    return @user.meals.none if from_date > to_date

    @user.meals.includes(:tags).between(from_date, to_date).order(created_at: :desc)
  end

  # デフォルト（全件・新しい順）
  def default_filter
    @user.meals.includes(:tags).order(created_at: :desc)
  end

  # 日付文字列をDateオブジェクトに変換（不正な場合はnilを返す）
  def parse_date(date_string)
    Date.parse(date_string)
  rescue ArgumentError
    nil
  end
end
