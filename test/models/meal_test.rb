# frozen_string_literal: true

require "test_helper"

class MealTest < ActiveSupport::TestCase
  def setup
    @user = active_user
    @meal = @user.meals.create!(
      meal_type: "breakfast",
      content: "Toast and eggs",
      eaten_on: Date.today
    )
  end

  # 有効な食事データが正しく作成されることを検証
  test "valid meal" do
    assert @meal.valid?
  end

  # meal_typeのバリデーションを検証
  test "meal_type validation" do
    # 正しいmeal_typeは保存できる
    Meal::MEAL_TYPES.each do |type|
      meal = @user.meals.new(meal_type: type, content: "test", eaten_on: Date.today)
      assert meal.valid?, "#{type} should be valid"
    end

    # 不正なmeal_typeは保存できない
    invalid_types = %w[invalid brunch teatime]
    invalid_types.each do |type|
      meal = @user.meals.new(meal_type: type, content: "test", eaten_on: Date.today)
      assert_not meal.valid?, "#{type} should be invalid"
    end
  end

  # contentのバリデーションを検証
  test "content validation" do
    # contentが必須
    @meal.content = nil
    assert_not @meal.valid?
    assert @meal.errors[:content].present?

    @meal.content = ""
    assert_not @meal.valid?
    assert @meal.errors[:content].present?

    # contentがあれば有効
    @meal.content = "Valid content"
    assert @meal.valid?
  end

  # eaten_onのバリデーションを検証
  test "eaten_on validation" do
    # eaten_onが必須
    @meal.eaten_on = nil
    assert_not @meal.valid?
    assert @meal.errors[:eaten_on].present?

    # eaten_onがあれば有効
    @meal.eaten_on = Date.today
    assert @meal.valid?
  end

  # ユーザーとの関連付けを検証
  test "belongs to user" do
    assert_equal @user, @meal.user
    assert_includes @user.meals, @meal
  end

  # タグのgetterとsetterが正しく動作することを検証
  test "tags getter and setter" do
    # tagsの設定（配列）
    @meal.tags = %w[healthy quick protein]
    @meal.save!

    # tags_textとして保存されている
    assert_equal "healthy,quick,protein", @meal.tags_text

    # tagsとして配列で取得できる
    assert_equal %w[healthy quick protein], @meal.tags
  end

  # 空の値を含むタグが除外されることを検証
  test "tags with empty values" do
    # 空の値は除外される
    @meal.tags = ["healthy", "", " ", "quick"]
    @meal.save!

    assert_equal "healthy,quick", @meal.tags_text
    assert_equal %w[healthy quick], @meal.tags
  end

  # 重複したタグが除外されることを検証
  test "tags with duplicates" do
    # 重複は除外される
    @meal.tags = %w[healthy healthy quick]
    @meal.save!

    assert_equal "healthy,quick", @meal.tags_text
    assert_equal %w[healthy quick], @meal.tags
  end

  # 空白を含むタグがトリムされることを検証
  test "tags with whitespace" do
    # 空白はトリムされる
    @meal.tags = [" healthy ", "quick  ", "  protein"]
    @meal.save!

    assert_equal "healthy,quick,protein", @meal.tags_text
    assert_equal %w[healthy quick protein], @meal.tags
  end

  # tags_textがnilの場合に空配列が返されることを検証
  test "tags from nil tags_text" do
    @meal.tags_text = nil
    assert_equal [], @meal.tags
  end

  # tags_textが空文字列の場合に空配列が返されることを検証
  test "tags from empty tags_text" do
    @meal.tags_text = ""
    assert_equal [], @meal.tags
  end

  # 栄養データが保存できることを検証
  test "nutrition data can be stored" do
    meal = @user.meals.create!(
      meal_type: "lunch",
      content: "Chicken salad",
      eaten_on: Date.today,
      calories: 450,
      grams: 300,
      protein: 35.5,
      fat: 15.2,
      carbohydrate: 42.3
    )

    assert_equal 450, meal.calories
    assert_equal 300, meal.grams
    assert_equal 35.5, meal.protein
    assert_equal 15.2, meal.fat
    assert_equal 42.3, meal.carbohydrate
  end

  # 栄養データがnilの場合を検証
  test "nutrition data can be nil" do
    meal = @user.meals.create!(
      meal_type: "snack",
      content: "Apple",
      eaten_on: Date.today
    )

    assert_nil meal.calories
    assert_nil meal.grams
    assert_nil meal.protein
    assert_nil meal.fat
    assert_nil meal.carbohydrate
  end

  # for_userスコープが特定ユーザーの食事のみ返すことを検証
  test "scopes - for_user" do
    user2 = User.create!(
      name: "User 2",
      email: "user2@example.com",
      password: "password",
      activated: true
    )

    meal2 = user2.meals.create!(
      meal_type: "dinner",
      content: "Steak",
      eaten_on: Date.today
    )

    user1_meals = Meal.for_user(@user)
    assert_includes user1_meals, @meal
    assert_not_includes user1_meals, meal2
  end

  # onスコープが特定日の食事のみ返すことを検証
  test "scopes - on" do
    today = Date.today
    yesterday = Date.yesterday

    yesterday_meal = @user.meals.create!(
      meal_type: "dinner",
      content: "Pasta",
      eaten_on: yesterday
    )

    today_meals = Meal.on(today)
    assert_includes today_meals, @meal
    assert_not_includes today_meals, yesterday_meal

    yesterday_meals = Meal.on(yesterday)
    assert_includes yesterday_meals, yesterday_meal
    assert_not_includes yesterday_meals, @meal
  end

  # betweenスコープが日付範囲内の食事のみ返すことを検証
  test "scopes - between" do
    today = Date.today
    yesterday = Date.yesterday
    two_days_ago = Date.today - 2

    yesterday_meal = @user.meals.create!(
      meal_type: "dinner",
      content: "Pasta",
      eaten_on: yesterday
    )

    old_meal = @user.meals.create!(
      meal_type: "breakfast",
      content: "Cereal",
      eaten_on: two_days_ago
    )

    range_meals = Meal.between(yesterday, today)
    assert_includes range_meals, @meal
    assert_includes range_meals, yesterday_meal
    assert_not_includes range_meals, old_meal

    # 単一日も範囲として扱える
    single_day = Meal.between(today, today)
    assert_includes single_day, @meal
    assert_not_includes single_day, yesterday_meal
  end

  # as_jsonが適切なフィールドを含むことを検証
  test "as_json includes proper fields" do
    meal = @user.meals.create!(
      meal_type: "lunch",
      content: "Test meal",
      eaten_on: Date.today,
      calories: 350,
      grams: 250,
      protein: 20,
      fat: 10,
      carbohydrate: 45
    )
    meal.tags = %w[healthy homemade]
    meal.save!
    meal.reload

    json = meal.as_json

    # 含まれるべきフィールド
    assert_equal meal.id, json["id"]
    assert_equal "lunch", json["meal_type"]
    assert_equal "Test meal", json["content"]
    assert_equal 350, json["calories"]
    assert_equal 250, json["grams"]
    assert_equal "20.0", json["protein"].to_s
    assert_equal "10.0", json["fat"].to_s
    assert_equal "45.0", json["carbohydrate"].to_s
    assert_equal meal.eaten_on.to_s, json["eaten_on"].to_s
    assert_equal %w[healthy homemade], json[:tags]

    # created_at, updated_atも含まれる
    assert json.key?("created_at")
    assert json.key?("updated_at")

    # user_idは含まれない（セキュリティ）
    assert_not json.key?("user_id")
  end
end
