require "test_helper"

class MealSummaryServiceTest < ActiveSupport::TestCase
  def setup
    @user = active_user
    @today = Date.today
    @yesterday = Date.yesterday

    # 各meal_typeのデータを作成
    @breakfast = @user.meals.create!(
      meal_type: "breakfast",
      content: "Breakfast",
      eaten_on: @today
    )

    @lunch = @user.meals.create!(
      meal_type: "lunch",
      content: "Lunch",
      eaten_on: @today
    )

    @dinner = @user.meals.create!(
      meal_type: "dinner",
      content: "Dinner",
      eaten_on: @today
    )

    @snack = @user.meals.create!(
      meal_type: "snack",
      content: "Snack",
      eaten_on: @today
    )

    @other = @user.meals.create!(
      meal_type: "other",
      content: "Other",
      eaten_on: @today
    )

    @yesterday_meal = @user.meals.create!(
      meal_type: "breakfast",
      content: "Yesterday breakfast",
      eaten_on: @yesterday
    )
  end

  test "returns summary with range and groups" do
    service = MealSummaryService.new(@user, {})
    result = service.call

    assert result.key?(:range)
    assert result.key?(:groups)
  end

  test "groups meals by type" do
    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    assert_equal 5, groups.keys.length
    assert groups.key?("breakfast")
    assert groups.key?("lunch")
    assert groups.key?("dinner")
    assert groups.key?("snack")
    assert groups.key?("other")
  end

  test "includes all meal types even when empty" do
    # 新しいユーザーで食事なし
    new_user = User.create!(
      name: "New User",
      email: "new@example.com",
      password: "password",
      activated: true
    )

    service = MealSummaryService.new(new_user, {})
    result = service.call

    groups = result[:groups]
    MealSummaryService::MEAL_TYPES.each do |type|
      assert groups.key?(type)
      assert_equal [], groups[type]
    end
  end

  test "groups contain correct meals for date filter" do
    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]

    assert_equal 1, groups["breakfast"].length
    assert_equal @breakfast.id, groups["breakfast"].first.id

    assert_equal 1, groups["lunch"].length
    assert_equal @lunch.id, groups["lunch"].first.id

    assert_equal 1, groups["dinner"].length
    assert_equal @dinner.id, groups["dinner"].first.id

    assert_equal 1, groups["snack"].length
    assert_equal @snack.id, groups["snack"].first.id

    assert_equal 1, groups["other"].length
    assert_equal @other.id, groups["other"].first.id
  end

  test "filters by date range" do
    params = { from: @yesterday.to_s, to: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]

    # 今日と昨日の朝食が含まれる
    assert_equal 2, groups["breakfast"].length
    breakfast_ids = groups["breakfast"].map(&:id)
    assert_includes breakfast_ids, @breakfast.id
    assert_includes breakfast_ids, @yesterday_meal.id
  end

  test "range info for single date" do
    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    range = result[:range]
    assert_equal @today.to_s, range[:date]
  end

  test "range info for date range" do
    params = { from: @yesterday.to_s, to: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    range = result[:range]
    assert_equal @yesterday.to_s, range[:from]
    assert_equal @today.to_s, range[:to]
  end

  test "range info when no filters" do
    service = MealSummaryService.new(@user, {})
    result = service.call

    range = result[:range]
    assert_nil range[:date]
    assert_nil range[:from]
    assert_nil range[:to]
  end

  test "handles multiple meals of same type" do
    # 2つ目の朝食を追加
    second_breakfast = @user.meals.create!(
      meal_type: "breakfast",
      content: "Second breakfast",
      eaten_on: @today
    )

    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    assert_equal 2, groups["breakfast"].length

    breakfast_ids = groups["breakfast"].map(&:id)
    assert_includes breakfast_ids, @breakfast.id
    assert_includes breakfast_ids, second_breakfast.id
  end

  test "only includes current user's meals" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )

    other_meal = other_user.meals.create!(
      meal_type: "breakfast",
      content: "Other user breakfast",
      eaten_on: @today
    )

    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    breakfast_ids = groups["breakfast"].map(&:id)
    assert_includes breakfast_ids, @breakfast.id
    assert_not_includes breakfast_ids, other_meal.id
  end

  test "empty groups for types without meals" do
    # 朝食のみのユーザー
    user = User.create!(
      name: "Breakfast User",
      email: "breakfast@example.com",
      password: "password",
      activated: true
    )

    user.meals.create!(
      meal_type: "breakfast",
      content: "Only breakfast",
      eaten_on: @today
    )

    params = { date: @today.to_s }
    service = MealSummaryService.new(user, params)
    result = service.call

    groups = result[:groups]
    assert_equal 1, groups["breakfast"].length
    assert_equal 0, groups["lunch"].length
    assert_equal 0, groups["dinner"].length
    assert_equal 0, groups["snack"].length
    assert_equal 0, groups["other"].length
  end

  test "uses MealFiltersService for filtering" do
    # MealFiltersServiceの動作を確認
    params = { date: @yesterday.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]

    # 昨日の食事のみ含まれる
    assert_equal 1, groups["breakfast"].length
    assert_equal @yesterday_meal.id, groups["breakfast"].first.id

    # 今日の食事は含まれない
    assert_equal 0, groups["lunch"].length
    assert_equal 0, groups["dinner"].length
    assert_equal 0, groups["snack"].length
    assert_equal 0, groups["other"].length
  end

  test "preserves meal order from filter service" do
    # 複数の朝食を時間差で作成
    first = @user.meals.create!(
      meal_type: "breakfast",
      content: "First",
      eaten_on: @today
    )
    sleep 0.01
    second = @user.meals.create!(
      meal_type: "breakfast",
      content: "Second",
      eaten_on: @today
    )

    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    breakfast_meals = groups["breakfast"]

    # created_at descの順序が保たれている
    assert_equal second.id, breakfast_meals[0].id
    assert_equal first.id, breakfast_meals[1].id
  end

  test "groups are arrays of meal objects" do
    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    groups.each do |type, meals|
      assert_kind_of Array, meals
      meals.each do |meal|
        assert_kind_of Meal, meal
        assert_equal type, meal.meal_type
      end
    end
  end

  test "handles invalid date gracefully" do
    params = { date: "invalid-date" }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    MealSummaryService::MEAL_TYPES.each do |type|
      assert_equal [], groups[type]
    end
  end

  test "meal objects include all attributes" do
    params = { date: @today.to_s }
    service = MealSummaryService.new(@user, params)
    result = service.call

    groups = result[:groups]
    meal = groups["breakfast"].first

    assert_equal @breakfast.id, meal.id
    assert_equal "breakfast", meal.meal_type
    assert_equal "Breakfast", meal.content
    assert_equal @today, meal.eaten_on
  end
end
