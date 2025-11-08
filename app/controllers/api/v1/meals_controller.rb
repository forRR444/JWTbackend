# frozen_string_literal: true

module Api
  module V1
    class MealsController < ApplicationController
      # 日付パラメータの検証用モジュール
      include DateRangeValidators

      before_action :authenticate_user # ログイン済みユーザーのみアクセス可
      before_action :set_meal, only: %i[show update destroy] # 食事レコード取得

      # ログインユーザーの食事一覧を取得
      def index
        meals = MealFiltersService.new(current_user, params).call
        render json: meals.as_json
      end

      # 特定の食事詳細を取得
      def show
        return not_found unless authorized_meal?

        render json: @meal.as_json
      end

      # 食事データを新規作成
      def create
        meal = current_user.meals.new(meal_params_with_tags)
        if meal.save
          render json: meal.as_json, status: :created
        else
          render_validation_errors(meal)
        end
      end

      # 食事データを更新
      def update
        return not_found unless authorized_meal?

        if @meal.update(meal_params_with_tags)
          render json: @meal.as_json
        else
          render_validation_errors(@meal)
        end
      end

      # 食事データを削除
      def destroy
        return not_found unless authorized_meal?

        @meal.destroy!
        head :no_content
      end

      # 食事データを種類（朝食/昼食/夕食/間食/その他）別に集計して返す
      def summary
        result = MealSummaryService.new(current_user, params).call
        render json: result
      end

      # 指定月の日別食事データを返す（カレンダー表示用）
      def calendar
        month = params[:month]
        return render_date_error("month required (YYYY-MM)") unless month
        return render_date_error("invalid month format") unless valid_month_format?(month)

        result = MealCalendarService.new(current_user, month).call
        render json: result
      end

      private

      # 対象の食事データを取得
      def set_meal
        @meal = Meal.includes(:tags).find_by(id: params[:id])
        not_found unless @meal
      end

      # 現在のユーザーが対象の食事にアクセス権限を持っているかチェック
      def authorized_meal?
        @meal.user_id == current_user.id
      end

      # 月の形式を検証（YYYY-MM形式かつ有効な月）
      def valid_month_format?(month)
        year, month_num = month.split("-").map(&:to_i)
        year.positive? && (1..12).cover?(month_num)
      end

      # 保存・更新時のバリデーションエラーをJSONで返す
      def render_validation_errors(meal)
        render json: { errors: meal.errors.full_messages }, status: :unprocessable_entity
      end

      # 食事登録・更新で受け取るパラメータ(タイミング、食事内容、日付、栄養情報、タグ)
      def meal_params
        params.require(:meal).permit(
          :meal_type,
          :content,
          :eaten_on,
          :calories,
          :grams,
          :protein,
          :fat,
          :carbohydrate
        )
      end

      # タグを含むパラメータを返す（tagsをtag_namesに変換）
      def meal_params_with_tags
        permitted = meal_params
        if params[:meal][:tags].present?
          permitted[:tag_names] = params[:meal][:tags]
        end
        permitted
      end
    end
  end
end
