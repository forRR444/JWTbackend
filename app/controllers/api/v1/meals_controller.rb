class Api::V1::MealsController < ApplicationController
  include DateRangeValidators

  before_action :authenticate_user
  before_action :set_meal, only: [ :show, :update, :destroy ]

  # GET /api/v1/meals
  # ログインユーザーの食事一覧
  def index
    meals = MealFiltersService.new(current_user, params).call
    render json: meals.as_json
  end

  # GET /api/v1/meals/:id
  def show
    return not_found unless @meal.user_id == current_user.id
    render json: @meal.as_json
  end

  # POST /api/v1/meals
  def create
    meal = current_user.meals.new(meal_params)
    if meal.save
      render json: meal.as_json, status: :created
    else
      render json: { errors: meal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /api/v1/meals/:id
  def update
    return not_found unless @meal.user_id == current_user.id
    if @meal.update(meal_params)
      render json: @meal.as_json
    else
      render json: { errors: meal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/meals/:id
  def destroy
    return not_found unless @meal.user_id == current_user.id
    @meal.destroy!
    head :no_content
  end

  # GET /api/v1/meals/summary
  # 種類ごとにグルーピングして返す
  def summary
    result = MealSummaryService.new(current_user, params).call
    render json: result
  end

  # GET /api/v1/meals/calendar
  # 日別件数を返す
  def calendar
    month = params[:month]
    return render_date_error("month required (YYYY-MM)") unless month

    # 月の形式を簡易検証
    year, month_num = month.split("-").map(&:to_i)
    unless year > 0 && (1..12).cover?(month_num)
      return render_date_error("invalid month format")
    end

    result = MealCalendarService.new(current_user, month).call
    render json: result
  end

  private

  def set_meal
    @meal = Meal.find_by(id: params[:id])
    not_found unless @meal
  end

  def meal_params
    # tags は配列として受け取り、モデル側で tags_text へ変換
    params.require(:meal).permit(:meal_type, :content, :eaten_on, :calories, :grams, tags: [])
  end
end
