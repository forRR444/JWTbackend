class Api::V1::MealsController < ApplicationController
  include DateRangeValidators

  before_action :authenticate_user
  before_action :set_meal, only: [ :show, :update, :destroy ]

  # GET /api/v1/meals
  # ログインユーザーの食事一覧を取得（フィルター可能）
  def index
    meals = MealFiltersService.new(current_user, params).call
    render json: meals.as_json
  end

  # GET /api/v1/meals/:id
  # 特定の食事詳細を取得
  def show
    return not_found unless authorized_meal?
    render json: @meal.as_json
  end

  # POST /api/v1/meals
  # 新しい食事を作成
  def create
    meal = current_user.meals.new(meal_params)

    if meal.save
      render json: meal.as_json, status: :created
    else
      render_validation_errors(meal)
    end
  end

  # PATCH /api/v1/meals/:id
  # 食事情報を更新
  def update
    return not_found unless authorized_meal?

    if @meal.update(meal_params)
      render json: @meal.as_json
    else
      render_validation_errors(@meal)
    end
  end

  # DELETE /api/v1/meals/:id
  # 食事を削除
  def destroy
    return not_found unless authorized_meal?
    @meal.destroy!
    head :no_content
  end

  # GET /api/v1/meals/summary
  # 食事を種類（朝食/昼食/夕食/間食/その他）ごとにグルーピングして返す
  def summary
    result = MealSummaryService.new(current_user, params).call
    render json: result
  end

  # GET /api/v1/meals/calendar
  # 指定月の日別食事件数を返す（カレンダー表示用）
  def calendar
    month = params[:month]
    return render_date_error("month required (YYYY-MM)") unless month

    return render_date_error("invalid month format") unless valid_month_format?(month)

    result = MealCalendarService.new(current_user, month).call
    render json: result
  end

  private

  # 食事レコードを取得してインスタンス変数にセット
  def set_meal
    @meal = Meal.find_by(id: params[:id])
    not_found unless @meal
  end

  # 現在のユーザーが対象の食事にアクセス権限を持っているかチェック
  def authorized_meal?
    @meal.user_id == current_user.id
  end

  # 月の形式を検証（YYYY-MM形式かつ有効な月）
  def valid_month_format?(month)
    year, month_num = month.split("-").map(&:to_i)
    year > 0 && (1..12).cover?(month_num)
  end

  # バリデーションエラーをレンダリング
  def render_validation_errors(meal)
    render json: { errors: meal.errors.full_messages }, status: :unprocessable_entity
  end

  # 食事パラメータの許可リスト
  # tags は配列として受け取り、モデル側で tags_text へ変換される
  def meal_params
    params.require(:meal).permit(
      :meal_type,
      :content,
      :eaten_on,
      :calories,
      :grams,
      :protein,
      :fat,
      :carbohydrate,
      tags: []
    )
  end
end
