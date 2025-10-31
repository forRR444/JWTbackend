# frozen_string_literal: true

require "test_helper"

class MealCalendarServiceTest < ActiveSupport::TestCase
  def setup
    @user = active_user
    @today = Date.today
    @month_string = @today.strftime("%Y-%m")
    @first_of_month = Date.new(@today.year, @today.month, 1)
    @last_of_month = @first_of_month.end_of_month
  end

  # 月と日のデータ構造が返されることを検証
  test "returns month and days structure" do
    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    assert result.key?(:month)
    assert result.key?(:days)
    assert_equal @month_string, result[:month]
    assert_kind_of Hash, result[:days]
  end

  # 日付キーに統計情報が含まれることを検証
  test "days contain date keys with statistics" do
    # 今月の食事を作成
    @user.meals.create!(
      meal_type: "breakfast",
      content: "Test meal",
      eaten_on: @today
    )

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    today_key = @today.to_s

    assert days.key?(today_key)
    day_data = days[today_key]

    assert day_data.key?(:total)
    assert day_data.key?(:by_type)
    assert day_data[:total] >= 1
  end

  # 合計カウントが食事数と一致することを検証
  test "total count matches number of meals" do
    # 今日に3つの食事を作成
    @user.meals.create!(meal_type: "breakfast", content: "Breakfast", eaten_on: @today)
    @user.meals.create!(meal_type: "lunch", content: "Lunch", eaten_on: @today)
    @user.meals.create!(meal_type: "dinner", content: "Dinner", eaten_on: @today)

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    today_data = days[@today.to_s]

    assert_equal 3, today_data[:total]
  end

  # タイプ別に食事が正しくグループ化されることを検証
  test "by_type groups meals correctly" do
    @user.meals.create!(meal_type: "breakfast", content: "Breakfast", eaten_on: @today)
    @user.meals.create!(meal_type: "breakfast", content: "Second breakfast", eaten_on: @today)
    @user.meals.create!(meal_type: "lunch", content: "Lunch", eaten_on: @today)

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    today_data = days[@today.to_s]
    by_type = today_data[:by_type]

    assert_equal 2, by_type["breakfast"]
    assert_equal 1, by_type["lunch"]
    assert_nil by_type["dinner"]
  end

  # 月内の食事がある全ての日が含まれることを検証
  test "includes all days with meals in the month" do
    # 月の最初と最後に食事を作成
    @user.meals.create!(
      meal_type: "breakfast",
      content: "First day",
      eaten_on: @first_of_month
    )

    @user.meals.create!(
      meal_type: "dinner",
      content: "Last day",
      eaten_on: @last_of_month
    )

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    assert days.key?(@first_of_month.to_s)
    assert days.key?(@last_of_month.to_s)
  end

  # 食事のない日が含まれないことを検証
  test "does not include days without meals" do
    # 食事がない日を確認
    no_meal_date = @first_of_month + 5

    # その日には食事を作らない
    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    # 食事がない日はキーに含まれない
    assert_not days.key?(no_meal_date.to_s)
  end

  # 指定月の食事のみ含まれることを検証
  test "only includes meals from specified month" do
    # 今月と来月の食事を作成
    @user.meals.create!(
      meal_type: "breakfast",
      content: "This month",
      eaten_on: @today
    )

    next_month = @today >> 1
    @user.meals.create!(
      meal_type: "breakfast",
      content: "Next month",
      eaten_on: next_month
    )

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    assert days.key?(@today.to_s)
    assert_not days.key?(next_month.to_s)
  end

  # 現在のユーザーの食事のみ含まれることを検証
  test "only includes current user's meals" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )

    @user.meals.create!(
      meal_type: "breakfast",
      content: "My meal",
      eaten_on: @today
    )

    other_user.meals.create!(
      meal_type: "breakfast",
      content: "Other user meal",
      eaten_on: @today
    )

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    today_data = days[@today.to_s]

    # 自分の食事のみカウント
    assert_equal 1, today_data[:total]
  end

  # 異なる月形式を処理できることを検証
  test "handles different month formats" do
    service = MealCalendarService.new(@user, "2025-01")
    result = service.call

    assert_equal "2025-01", result[:month]
    assert_kind_of Hash, result[:days]
  end

  # 閏年の2月を処理できることを検証
  test "handles edge case of February in leap year" do
    leap_year_month = "2024-02"
    service = MealCalendarService.new(@user, leap_year_month)

    # エラーなく実行できることを確認
    assert_nothing_raised do
      result = service.call
      assert_equal leap_year_month, result[:month]
    end
  end

  # 平年の2月を処理できることを検証
  test "handles edge case of February in non-leap year" do
    non_leap_year_month = "2025-02"
    service = MealCalendarService.new(@user, non_leap_year_month)

    assert_nothing_raised do
      result = service.call
      assert_equal non_leap_year_month, result[:month]
    end
  end

  # 31日ある月を処理できることを検証
  test "handles month with 31 days" do
    month_31_days = "2025-01"
    service = MealCalendarService.new(@user, month_31_days)

    assert_nothing_raised do
      result = service.call
      assert_equal month_31_days, result[:month]
    end
  end

  # 30日ある月を処理できることを検証
  test "handles month with 30 days" do
    month_30_days = "2025-04"
    service = MealCalendarService.new(@user, month_30_days)

    assert_nothing_raised do
      result = service.call
      assert_equal month_30_days, result[:month]
    end
  end

  # 複数日に複数の食事がある場合を検証
  test "multiple meals on multiple days" do
    # 3日間、各日2食
    day1 = @first_of_month
    day2 = @first_of_month + 1
    day3 = @first_of_month + 2

    [day1, day2, day3].each do |day|
      @user.meals.create!(meal_type: "breakfast", content: "Breakfast", eaten_on: day)
      @user.meals.create!(meal_type: "lunch", content: "Lunch", eaten_on: day)
    end

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]

    [day1, day2, day3].each do |day|
      day_data = days[day.to_s]
      assert_equal 2, day_data[:total]
      assert_equal 1, day_data[:by_type]["breakfast"]
      assert_equal 1, day_data[:by_type]["lunch"]
    end
  end

  # 全ての食事タイプが個別にカウントされることを検証
  test "counts all meal types separately" do
    @user.meals.create!(meal_type: "breakfast", content: "Breakfast", eaten_on: @today)
    @user.meals.create!(meal_type: "lunch", content: "Lunch", eaten_on: @today)
    @user.meals.create!(meal_type: "dinner", content: "Dinner", eaten_on: @today)
    @user.meals.create!(meal_type: "snack", content: "Snack", eaten_on: @today)
    @user.meals.create!(meal_type: "other", content: "Other", eaten_on: @today)

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    today_data = days[@today.to_s]

    assert_equal 5, today_data[:total]
    assert_equal 1, today_data[:by_type]["breakfast"]
    assert_equal 1, today_data[:by_type]["lunch"]
    assert_equal 1, today_data[:by_type]["dinner"]
    assert_equal 1, today_data[:by_type]["snack"]
    assert_equal 1, today_data[:by_type]["other"]
  end

  # 食事のない月で空のハッシュが返されることを検証
  test "empty month returns empty days hash" do
    # 未来の月で食事なし
    future_month = (@today >> 6).strftime("%Y-%m")

    service = MealCalendarService.new(@user, future_month)
    result = service.call

    assert_equal future_month, result[:month]
    assert_equal({}, result[:days])
  end

  # 過去の月の食事を取得できることを検証
  test "past month with meals" do
    past_month = (@today << 1)
    past_month_string = past_month.strftime("%Y-%m")

    # 先月の食事を作成
    @user.meals.create!(
      meal_type: "breakfast",
      content: "Past meal",
      eaten_on: past_month
    )

    service = MealCalendarService.new(@user, past_month_string)
    result = service.call

    days = result[:days]
    assert days.key?(past_month.to_s)
    assert_equal 1, days[past_month.to_s][:total]
  end

  # 日付キーがISO 8601形式であることを検証
  test "date string keys are in ISO 8601 format" do
    @user.meals.create!(
      meal_type: "breakfast",
      content: "Test",
      eaten_on: @today
    )

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    days.each_key do |date_key|
      # YYYY-MM-DD 形式であることを確認
      assert_match(/^\d{4}-\d{2}-\d{2}$/, date_key)
    end
  end

  # by_typeに存在するタイプのみ含まれることを検証
  test "by_type only includes types that exist" do
    @user.meals.create!(meal_type: "breakfast", content: "Breakfast", eaten_on: @today)

    service = MealCalendarService.new(@user, @month_string)
    result = service.call

    days = result[:days]
    by_type = days[@today.to_s][:by_type]

    assert_equal 1, by_type["breakfast"]
    assert_nil by_type["lunch"]
    assert_nil by_type["dinner"]
  end
end
