# frozen_string_literal: true

# 食品データの検索API
# ユーザーが入力したキーワードで食品を検索し、栄養情報を返す
module Api
  module V1
    class FoodsController < ApplicationController
      before_action :authenticate_user # ログイン済みユーザーのみアクセス可

      # 食品検索API
      def index
        query = params[:q]
        # 検索ワードが空なら空配列を返す
        if query.blank?
          render json: { foods: [] }, status: :ok
          return
        end

        # 食品名で検索(部分一致)し、最大20件返す
        foods = Food.search_by_name(query).with_nutrition.limit(20)
        # 栄養素を抽出して返す
        render json: {
          foods: foods.map do |food|
            {
              id: food.id,
              name: food.name,
              calories: food.calories,
              protein: food.protein,
              fat: food.fat,
              carbohydrate: food.carbohydrate
            }
          end
        }, status: :ok
      end
    end
  end
end
