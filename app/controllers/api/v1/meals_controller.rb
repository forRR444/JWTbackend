class Api::V1::MealsController < ApplicationController
  before_action :authenticate_user
  before_action :set_meal, only: [:show, :update, :destroy]

  # GET /api/v1/meals
  # ログインユーザーの食事一覧
  def index
    meals = current_user.meals.order(created_at: :desc).limit(200)
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
      render status: 201, json: meal.as_json
    else
      render status: 422, json: { errors: meal.errors.full_messages }
    end
  end

  # PATCH/PUT /api/v1/meals/:id
  def update
    return not_found unless @meal.user_id == current_user.id
    if @meal.update(meal_params)
      render json: @meal.as_json
    else
      render status: 422, json: { errors: @meal.errors.full_messages }
    end
  end

  # DELETE /api/v1/meals/:id
  def destroy
    return not_found unless @meal.user_id == current_user.id
    @meal.destroy!
    head :no_content
  end

  private

    def set_meal
      @meal = Meal.find_by(id: params[:id])
      not_found unless @meal
    end

    def meal_params
      # tags は配列として受け取り、モデル側で tags_text へ変換
      params.require(:meal).permit(:meal_type, :content, :calories, :grams, tags: [])
    end
end
