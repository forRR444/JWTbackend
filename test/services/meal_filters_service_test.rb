require "test_helper"

class MealFiltersServiceTest < ActiveSupport::TestCase
  def setup
    @user = active_user

    # テスト用の食事データ
    @today = Date.today
    @yesterday = Date.yesterday
    @two_days_ago = @today - 2
    @three_days_ago = @today - 3

    @meal_today = @user.meals.create!(
      meal_type: "breakfast",
      content: "Today's breakfast",
      eaten_on: @today
    )

    @meal_yesterday = @user.meals.create!(
      meal_type: "lunch",
      content: "Yesterday's lunch",
      eaten_on: @yesterday
    )

    @meal_two_days_ago = @user.meals.create!(
      meal_type: "dinner",
      content: "Two days ago dinner",
      eaten_on: @two_days_ago
    )

    @meal_three_days_ago = @user.meals.create!(
      meal_type: "snack",
      content: "Three days ago snack",
      eaten_on: @three_days_ago
    )
  end

  test "returns all meals when no filters" do
    service = MealFiltersService.new(@user, {})
    meals = service.call

    assert_includes meals, @meal_today
    assert_includes meals, @meal_yesterday
    assert_includes meals, @meal_two_days_ago
    assert_includes meals, @meal_three_days_ago
    assert meals.count >= 4
  end

  test "orders by created_at desc by default" do
    service = MealFiltersService.new(@user, {})
    meals = service.call.to_a

    # 新しく作成されたものが先に来る
    assert_equal @meal_three_days_ago.id, meals[0].id
    assert_equal @meal_two_days_ago.id, meals[1].id
    assert_equal @meal_yesterday.id, meals[2].id
    assert_equal @meal_today.id, meals[3].id
  end

  test "filters by single date" do
    params = { date: @today.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_includes meals, @meal_today
    assert_not_includes meals, @meal_yesterday
    assert_not_includes meals, @meal_two_days_ago
    assert_not_includes meals, @meal_three_days_ago
    assert_equal 1, meals.count
  end

  test "filters by date range" do
    params = { from: @two_days_ago.to_s, to: @today.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_includes meals, @meal_today
    assert_includes meals, @meal_yesterday
    assert_includes meals, @meal_two_days_ago
    assert_not_includes meals, @meal_three_days_ago
    assert_equal 3, meals.count
  end

  test "filters by date range inclusive of both ends" do
    params = { from: @yesterday.to_s, to: @yesterday.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_not_includes meals, @meal_today
    assert_includes meals, @meal_yesterday
    assert_not_includes meals, @meal_two_days_ago
    assert_equal 1, meals.count
  end

  test "returns empty when date is invalid" do
    params = { date: "invalid-date" }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_equal 0, meals.count
  end

  test "returns empty when from date is invalid" do
    params = { from: "invalid-date", to: @today.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_equal 0, meals.count
  end

  test "returns empty when to date is invalid" do
    params = { from: @yesterday.to_s, to: "invalid-date" }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_equal 0, meals.count
  end

  test "returns empty when from is after to" do
    params = { from: @today.to_s, to: @yesterday.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_equal 0, meals.count
  end

  test "only returns current user's meals" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )

    other_meal = other_user.meals.create!(
      meal_type: "breakfast",
      content: "Other user's meal",
      eaten_on: @today
    )

    service = MealFiltersService.new(@user, {})
    meals = service.call

    assert_includes meals, @meal_today
    assert_not_includes meals, other_meal
  end

  test "date filter takes precedence over range filter" do
    # 両方指定された場合、dateが優先される
    params = { date: @today.to_s, from: @three_days_ago.to_s, to: @today.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_includes meals, @meal_today
    assert_not_includes meals, @meal_yesterday
    assert_equal 1, meals.count
  end

  test "handles date with time information" do
    params = { date: "#{@today} 12:00:00" }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_includes meals, @meal_today
    assert_equal 1, meals.count
  end

  test "handles ISO 8601 date format" do
    params = { date: @today.iso8601 }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_includes meals, @meal_today
    assert_equal 1, meals.count
  end

  test "filters multiple meals on same date" do
    @user.meals.create!(
      meal_type: "lunch",
      content: "Today's lunch",
      eaten_on: @today
    )

    @user.meals.create!(
      meal_type: "dinner",
      content: "Today's dinner",
      eaten_on: @today
    )

    params = { date: @today.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert meals.count >= 3
    meals.each do |meal|
      assert_equal @today, meal.eaten_on
    end
  end

  test "returns active record relation" do
    service = MealFiltersService.new(@user, {})
    result = service.call

    assert_kind_of ActiveRecord::Relation, result
  end

  test "can chain additional scopes" do
    service = MealFiltersService.new(@user, {})
    meals = service.call.where(meal_type: "breakfast")

    assert_includes meals, @meal_today
    assert_not_includes meals, @meal_yesterday
  end

  test "filters by future date" do
    future_date = @today + 7
    params = { date: future_date.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    assert_equal 0, meals.count
  end

  test "filters by range with only from date" do
    # fromだけでtoがない場合は範囲フィルタは適用されない
    params = { from: @yesterday.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    # デフォルトフィルタが適用される
    assert meals.count >= 4
  end

  test "filters by range with only to date" do
    # toだけでfromがない場合は範囲フィルタは適用されない
    params = { to: @yesterday.to_s }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    # デフォルトフィルタが適用される
    assert meals.count >= 4
  end

  test "handles edge case with blank date string" do
    params = { date: "" }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    # 空文字列はpresent?でfalseになるのでデフォルトフィルタ
    assert meals.count >= 4
  end

  test "handles edge case with nil date" do
    params = { date: nil }
    service = MealFiltersService.new(@user, params)
    meals = service.call

    # nilはpresent?でfalseになるのでデフォルトフィルタ
    assert meals.count >= 4
  end
end
