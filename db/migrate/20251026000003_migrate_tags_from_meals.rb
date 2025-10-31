# frozen_string_literal: true

class MigrateTagsFromMeals < ActiveRecord::Migration[8.0]
  def up
    # 既存のmealsテーブルのtags_textからデータを移行
    # 1. 既存のタグを全て抽出してtagsテーブルに登録
    all_tags = Set.new

    Meal.find_each do |meal|
      next if meal.tags_text.blank?

      tags = meal.tags_text.split(",").map(&:strip).reject(&:blank?)
      all_tags.merge(tags)
    end

    # タグマスタを作成
    all_tags.each do |tag_name|
      Tag.find_or_create_by!(name: tag_name)
    end

    # 2. 各mealのタグをmeal_tagsに移行
    Meal.find_each do |meal|
      next if meal.tags_text.blank?

      tag_names = meal.tags_text.split(",").map(&:strip).reject(&:blank?)
      tag_names.each do |tag_name|
        tag = Tag.find_by!(name: tag_name)
        MealTag.find_or_create_by!(meal_id: meal.id, tag_id: tag.id)
      end
    end

    # 3. tags_textカラムを削除
    remove_column :meals, :tags_text
  end

  def down
    # ロールバック用: tags_textカラムを追加して復元
    add_column :meals, :tags_text, :string

    Meal.find_each do |meal|
      tag_names = meal.tags.pluck(:name)
      meal.update_column(:tags_text, tag_names.join(",")) if tag_names.any?
    end
  end
end
