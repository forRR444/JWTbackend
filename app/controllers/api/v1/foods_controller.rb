class Api::V1::FoodsController < ApplicationController
  before_action :authenticate_user

  # GET /api/v1/foods?q=鶏肉
  def index
    query = params[:q]

    if query.blank?
      render json: { foods: [] }, status: :ok
      return
    end

    # 食品名で検索し、最大20件まで返す
    foods = Food.search_by_name(query).with_nutrition.limit(20)

    render json: {
      foods: foods.map { |food|
        {
          id: food.id,
          name: food.name,
          calories: food.calories,
          protein: food.protein,
          fat: food.fat,
          carbohydrate: food.carbohydrate
        }
      }
    }, status: :ok
  end
end
