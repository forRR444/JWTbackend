class Api::V1::MealsController < ApplicationController
  before_action :authenticate_user
  before_action :set_meal, only: [:show, :update, :destroy]

  # GET /api/v1/meals
  # ログインユーザーの食事一覧
  def index
    meals = current_user.meals.order(created_at: :desc).limit(200)
    
    if params[:date].present?
      d = Date.parse(params[:date]) rescue nil
      return render json: { error: "invalid date" }, status: :bad_request unless d
      meals = current_user.meals.on(d).order(created_at: :desc)
    elsif params[:from].present? && params[:to].present?
      from = Date.parse(params[:from]) rescue nil
      to   = Date.parse(params[:to]) rescue nil
      return render json: { error: "invalid range" }, status: :bad_request unless from && to && from <= to
      meals = current_user.meals.between(from, to).order(:eaten_on, :created_at)
    end

    render json: meals.as_json
  end

  # GET /api/v1/meals/:id
  def show
    return not_found unless @meal.user_id == current_user.id
    render json: @meal.as_json
  end

  # create/update に eaten_on を許可
  def create
    meal = current_user.meals.new(meal_params)
    if meal.save
      render json: meal.as_json, status: :created
    else
      render json: { errors: meal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    return not_found unless @meal.user_id == current_user.id
    if @meal.update(meal_params)
      render json: @meal.as_json
    else
      render json: { errors: @meal.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/meals/:id
  def destroy
    return not_found unless @meal.user_id == current_user.id
    @meal.destroy!
    head :no_content
  end

  # 種類ごとにグルーピングして返す
  def summary
    records =
      if params[:date].present?
        d = Date.parse(params[:date]) rescue nil
        return render json: { error: "invalid date" }, status: :bad_request unless d
        current_user.meals.on(d)
      else
        from = Date.parse(params[:from]) rescue nil
        to   = Date.parse(params[:to]) rescue nil
        return render json: { error: "date or (from,to) required" }, status: :bad_request unless from && to
        return render json: { error: "invalid range" }, status: :bad_request unless from <= to
        current_user.meals.between(from, to)
      end

    grouped = Meal::MEAL_TYPES.index_with { [] }
    records.order(:meal_type, :created_at).each do |m|
      (grouped[m.meal_type] ||= []) << m.as_json
    end

    render json: {
      range: {
        date: params[:date],
        from: params[:from],
        to:   params[:to]
      },
      groups: grouped # { "breakfast": [...], "lunch": [...], ... }
    }
  end

  # 日別件数を返す
  def calendar
    month = params[:month]
    return render json: { error: "month required (YYYY-MM)" }, status: :bad_request unless month
    y, m = month.split("-").map(&:to_i)
    return render json: { error: "invalid month" }, status: :bad_request unless y > 0 && (1..12).include?(m)

    from = Date.new(y, m, 1)
    to   = from.end_of_month

    rows = current_user.meals
      .between(from, to)
      .group(:eaten_on, :meal_type)
      .count # => { [eaten_on, meal_type] => n }

    # 集計整形: { "2025-10-01": { total: 3, by_type: { "breakfast":1, ... } }, ... }
    days = {}
    (from..to).each { |d| days[d.to_s] = { total: 0, by_type: {} } }

    rows.each do |(d, type), n|
      key = d.to_s
      days[key][:by_type][type] = n
      days[key][:total] += n
    end

    render json: { month: month, days: days }
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
