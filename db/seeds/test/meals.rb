# frozen_string_literal: true

# テスト用食事データ
# ユーザーが存在することが前提
user1 = User.find_by(email: "test_user0@example.com")
user2 = User.find_by(email: "test_user1@example.com")

if user1.nil? || user2.nil?
  puts "Warning: テストユーザーが見つかりません。先にusersのシードを実行してください。"
  return
end

# 既存のテスト用mealデータを削除（冪等性を保つため）
Meal.where(user: [user1, user2]).destroy_all

meals_data = [
  {
    user: user1,
    meal_type: "breakfast",
    content: "Toast and scrambled eggs",
    eaten_on: Date.today,
    calories: 350,
    grams: 200,
    protein: 15.5,
    fat: 12.0,
    carbohydrate: 40.0,
    tags: %w[healthy quick]
  },
  {
    user: user1,
    meal_type: "lunch",
    content: "Chicken salad",
    eaten_on: Date.today,
    calories: 400,
    grams: 300,
    protein: 30.0,
    fat: 15.0,
    carbohydrate: 35.0,
    tags: %w[protein salad]
  },
  {
    user: user1,
    meal_type: "dinner",
    content: "Grilled salmon with vegetables",
    eaten_on: Date.yesterday,
    calories: 500,
    grams: 350,
    protein: 40.0,
    fat: 20.0,
    carbohydrate: 30.0,
    tags: %w[fish healthy]
  },
  {
    user: user2,
    meal_type: "breakfast",
    content: "Cereal with milk",
    eaten_on: Date.today,
    calories: 250,
    grams: 250,
    protein: 8.0,
    fat: 5.0,
    carbohydrate: 45.0,
    tags: ["quick"]
  },
  {
    user: user1,
    meal_type: "snack",
    content: "Apple and almonds",
    eaten_on: Date.today,
    calories: 150,
    grams: 100,
    protein: 5.0,
    fat: 8.0,
    carbohydrate: 20.0,
    tags: %w[healthy snack]
  }
]

meals_data.each do |data|
  Meal.create!(data)
end

puts "test meals = #{Meal.count}"
