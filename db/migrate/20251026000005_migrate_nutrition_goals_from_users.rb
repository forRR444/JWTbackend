# frozen_string_literal: true

class MigrateNutritionGoalsFromUsers < ActiveRecord::Migration[8.0]
  def up
    # 既存のusersテーブルの目標データをnutrition_goalsに移行
    User.find_each do |user|
      # 目標値が設定されているユーザーのみ移行
      if user.target_calories.present? ||
         user.target_protein.present? ||
         user.target_fat.present? ||
         user.target_carbohydrate.present?

        NutritionGoal.create!(
          user_id: user.id,
          target_calories: user.target_calories,
          target_protein: user.target_protein,
          target_fat: user.target_fat,
          target_carbohydrate: user.target_carbohydrate,
          start_date: user.created_at.to_date, # ユーザー作成日から有効
          end_date: nil # 現在有効
        )
      end
    end

    # usersテーブルから目標カラムを削除
    remove_column :users, :target_calories
    remove_column :users, :target_protein
    remove_column :users, :target_fat
    remove_column :users, :target_carbohydrate
  end

  def down
    # ロールバック用: カラムを復元
    add_column :users, :target_calories, :integer, comment: "目標カロリー (kcal)"
    add_column :users, :target_protein, :decimal, precision: 8, scale: 1, comment: "目標たんぱく質 (g)"
    add_column :users, :target_fat, :decimal, precision: 8, scale: 1, comment: "目標脂質 (g)"
    add_column :users, :target_carbohydrate, :decimal, precision: 8, scale: 1, comment: "目標炭水化物 (g)"

    # 最新の目標をusersテーブルに戻す
    User.find_each do |user|
      goal = user.nutrition_goals.order(start_date: :desc).first
      if goal
        user.update_columns(
          target_calories: goal.target_calories,
          target_protein: goal.target_protein,
          target_fat: goal.target_fat,
          target_carbohydrate: goal.target_carbohydrate
        )
      end
    end
  end
end
