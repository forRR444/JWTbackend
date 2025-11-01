require "test_helper"

class Api::V1::MealsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = active_user
    @token = @user.encode_access_token
    @headers = auth(@token.token)

    @meal = @user.meals.create!(
      meal_type: "breakfast",
      content: "Toast and eggs",
      eaten_on: Date.today,
      calories: 350,
      protein: 15,
      fat: 12,
      carbohydrate: 40,
      tags: [ "healthy", "quick" ]
    )
  end

  # ユーザーの食事一覧が取得できることを検証
  test "index returns user's meals" do
    get api("/meals"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_kind_of Array, json
    assert json.length >= 1

    meal_json = json.find { |m| m["id"] == @meal.id }
    assert_not_nil meal_json
    assert_equal "breakfast", meal_json["meal_type"]
    assert_equal "Toast and eggs", meal_json["content"]
  end

  # 認証が必要であることを検証
  test "index requires authentication" do
    get api("/meals"), xhr: true
    assert_response :unauthorized
  end

  # 日付フィルタが正しく動作することを検証
  test "index with date filter" do
    yesterday_meal = @user.meals.create!(
      meal_type: "dinner",
      content: "Pasta",
      eaten_on: Date.yesterday
    )

    get api("/meals?date=#{Date.today}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    meal_ids = json.map { |m| m["id"] }
    assert_includes meal_ids, @meal.id
    assert_not_includes meal_ids, yesterday_meal.id
  end

  # 日付範囲フィルタが正しく動作することを検証
  test "index with date range filter" do
    old_meal = @user.meals.create!(
      meal_type: "breakfast",
      content: "Cereal",
      eaten_on: Date.today - 5
    )

    from_date = Date.yesterday
    to_date = Date.today

    get api("/meals?from=#{from_date}&to=#{to_date}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    meal_ids = json.map { |m| m["id"] }
    assert_includes meal_ids, @meal.id
    assert_not_includes meal_ids, old_meal.id
  end

  # 現在のユーザーの食事のみ返すことを検証
  test "index only returns current user's meals" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )
    other_meal = other_user.meals.create!(
      meal_type: "lunch",
      content: "Salad",
      eaten_on: Date.today
    )

    get api("/meals"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    meal_ids = json.map { |m| m["id"] }
    assert_includes meal_ids, @meal.id
    assert_not_includes meal_ids, other_meal.id
  end

  # GET /api/v1/meals/:id
  # 食事の詳細が取得できることを検証
  test "show returns meal details" do
    get api("/meals/#{@meal.id}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal @meal.id, json["id"]
    assert_equal "breakfast", json["meal_type"]
    assert_equal "Toast and eggs", json["content"]
    assert_equal 350, json["calories"]
    assert_equal [ "healthy", "quick" ], json["tags"]
  end

  # 認証が必要であることを検証
  test "show requires authentication" do
    get api("/meals/#{@meal.id}"), xhr: true
    assert_response :unauthorized
  end

  # 存在しない食事に対して404を返すことを検証
  test "show returns not found for non-existent meal" do
    get api("/meals/999999"), xhr: true, headers: @headers
    assert_response :not_found
  end

  # 他のユーザーの食事に対して404を返すことを検証
  test "show returns not found for other user's meal" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )
    other_meal = other_user.meals.create!(
      meal_type: "lunch",
      content: "Salad",
      eaten_on: Date.today
    )

    get api("/meals/#{other_meal.id}"), xhr: true, headers: @headers
    assert_response :not_found
  end

  # POST /api/v1/meals
  # 新しい食事が作成できることを検証
  test "create creates a new meal" do
    meal_params = {
      meal: {
        meal_type: "lunch",
        content: "Chicken salad",
        eaten_on: Date.today,
        calories: 400,
        protein: 30,
        fat: 15,
        carbohydrate: 35,
        tags: [ "protein", "salad" ]
      }
    }

    assert_difference("@user.meals.count", 1) do
      post api("/meals"), xhr: true, headers: @headers, params: meal_params, as: :json
    end

    assert_response :created

    json = res_body
    assert_equal "lunch", json["meal_type"]
    assert_equal "Chicken salad", json["content"]
    assert_equal 400, json["calories"]
    assert_equal "30.0", json["protein"].to_s
    assert_equal [ "protein", "salad" ], json[:tags]
  end

  # 認証が必要であることを検証
  test "create requires authentication" do
    meal_params = {
      meal: {
        meal_type: "lunch",
        content: "Test",
        eaten_on: Date.today
      }
    }

    post api("/meals"), xhr: true, params: meal_params, as: :json
    assert_response :unauthorized
  end

  # meal_typeのバリデーションを検証
  test "create validates meal_type" do
    meal_params = {
      meal: {
        meal_type: "invalid_type",
        content: "Test",
        eaten_on: Date.today
      }
    }

    assert_no_difference("@user.meals.count") do
      post api("/meals"), xhr: true, headers: @headers, params: meal_params, as: :json
    end

    assert_response :unprocessable_entity
    json = res_body
    assert json.key?("errors")
  end

  # contentの必須検証を確認
  test "create validates content presence" do
    meal_params = {
      meal: {
        meal_type: "lunch",
        content: "",
        eaten_on: Date.today
      }
    }

    assert_no_difference("@user.meals.count") do
      post api("/meals"), xhr: true, headers: @headers, params: meal_params, as: :json
    end

    assert_response :unprocessable_entity
  end

  # eaten_onの必須検証を確認
  test "create validates eaten_on presence" do
    meal_params = {
      meal: {
        meal_type: "lunch",
        content: "Test",
        eaten_on: nil
      }
    }

    assert_no_difference("@user.meals.count") do
      post api("/meals"), xhr: true, headers: @headers, params: meal_params, as: :json
    end

    assert_response :unprocessable_entity
  end

  # 最小限のパラメータで作成できることを検証
  test "create with minimal params" do
    meal_params = {
      meal: {
        meal_type: "snack",
        content: "Apple",
        eaten_on: Date.today
      }
    }

    assert_difference("@user.meals.count", 1) do
      post api("/meals"), xhr: true, headers: @headers, params: meal_params, as: :json
    end

    assert_response :created

    json = res_body
    assert_equal "snack", json["meal_type"]
    assert_equal "Apple", json["content"]
    assert_nil json["calories"]
  end

  # PATCH /api/v1/meals/:id
  # 食事が更新できることを検証
  test "update updates meal" do
    update_params = {
      meal: {
        content: "Updated content",
        calories: 500
      }
    }

    patch api("/meals/#{@meal.id}"), xhr: true, headers: @headers, params: update_params, as: :json
    assert_response :success

    json = res_body
    assert_equal "Updated content", json["content"]
    assert_equal 500, json["calories"]

    @meal.reload
    assert_equal "Updated content", @meal.content
    assert_equal 500, @meal.calories
  end

  # 認証が必要であることを検証
  test "update requires authentication" do
    update_params = {
      meal: {
        content: "Updated content"
      }
    }

    patch api("/meals/#{@meal.id}"), xhr: true, params: update_params, as: :json
    assert_response :unauthorized
  end

  # 存在しない食事に対して404を返すことを検証
  test "update returns not found for non-existent meal" do
    update_params = {
      meal: {
        content: "Updated content"
      }
    }

    patch api("/meals/999999"), xhr: true, headers: @headers, params: update_params, as: :json
    assert_response :not_found
  end

  # 他のユーザーの食事に対して404を返すことを検証
  test "update returns not found for other user's meal" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )
    other_meal = other_user.meals.create!(
      meal_type: "lunch",
      content: "Salad",
      eaten_on: Date.today
    )

    update_params = {
      meal: {
        content: "Hacked content"
      }
    }

    patch api("/meals/#{other_meal.id}"), xhr: true, headers: @headers, params: update_params, as: :json
    assert_response :not_found

    other_meal.reload
    assert_equal "Salad", other_meal.content
  end

  # meal_typeのバリデーションを検証
  test "update validates meal_type" do
    update_params = {
      meal: {
        meal_type: "invalid_type"
      }
    }

    patch api("/meals/#{@meal.id}"), xhr: true, headers: @headers, params: update_params, as: :json
    assert_response :unprocessable_entity
  end

  # タグの変更ができることを検証
  test "update can change tags" do
    update_params = {
      meal: {
        tags: [ "new_tag", "another_tag" ]
      }
    }

    patch api("/meals/#{@meal.id}"), xhr: true, headers: @headers, params: update_params, as: :json
    assert_response :success

    json = res_body
    assert_equal [ "new_tag", "another_tag" ], json["tags"]
  end

  # DELETE /api/v1/meals/:id
  # 食事が削除できることを検証
  test "destroy deletes meal" do
    assert_difference("@user.meals.count", -1) do
      delete api("/meals/#{@meal.id}"), xhr: true, headers: @headers
    end

    assert_response :no_content
    assert_nil Meal.find_by(id: @meal.id)
  end

  # 認証が必要であることを検証
  test "destroy requires authentication" do
    delete api("/meals/#{@meal.id}"), xhr: true
    assert_response :unauthorized

    assert_not_nil Meal.find_by(id: @meal.id)
  end

  # 存在しない食事に対して404を返すことを検証
  test "destroy returns not found for non-existent meal" do
    delete api("/meals/999999"), xhr: true, headers: @headers
    assert_response :not_found
  end

  # 他のユーザーの食事に対して404を返すことを検証
  test "destroy returns not found for other user's meal" do
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )
    other_meal = other_user.meals.create!(
      meal_type: "lunch",
      content: "Salad",
      eaten_on: Date.today
    )

    delete api("/meals/#{other_meal.id}"), xhr: true, headers: @headers
    assert_response :not_found

    assert_not_nil Meal.find_by(id: other_meal.id)
  end

  # GET /api/v1/meals/summary
  # 食事タイプ別のサマリーが取得できることを検証
  test "summary returns meals grouped by type" do
    @user.meals.create!(
      meal_type: "lunch",
      content: "Salad",
      eaten_on: Date.today
    )
    @user.meals.create!(
      meal_type: "dinner",
      content: "Steak",
      eaten_on: Date.today
    )

    get api("/meals/summary?date=#{Date.today}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert json.key?("range")
    assert json.key?("groups")

    groups = json["groups"]
    assert groups.key?("breakfast")
    assert groups.key?("lunch")
    assert groups.key?("dinner")
    assert groups.key?("snack")
    assert groups.key?("other")

    assert groups["breakfast"].length >= 1
    assert groups["lunch"].length >= 1
    assert groups["dinner"].length >= 1
  end

  # 認証が必要であることを検証
  test "summary requires authentication" do
    get api("/meals/summary"), xhr: true
    assert_response :unauthorized
  end

  # 日付範囲指定でサマリーが取得できることを検証
  test "summary with date range" do
    get api("/meals/summary?from=#{Date.yesterday}&to=#{Date.today}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal Date.yesterday.to_s, json["range"]["from"]
    assert_equal Date.today.to_s, json["range"]["to"]
  end

  # GET /api/v1/meals/calendar
  # 月別の食事カウントが取得できることを検証
  test "calendar returns monthly meal counts" do
    month = Date.today.strftime("%Y-%m")

    get api("/meals/calendar?month=#{month}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal month, json["month"]
    assert json.key?("days")

    days = json["days"]
    assert_kind_of Hash, days

    # 今日の日付のキーが存在する
    today_key = Date.today.to_s
    if days.key?(today_key)
      day_data = days[today_key]
      assert day_data.key?("total")
      assert day_data.key?("by_type")
      assert day_data["total"] >= 1
    end
  end

  # 認証が必要であることを検証
  test "calendar requires authentication" do
    month = Date.today.strftime("%Y-%m")
    get api("/meals/calendar?month=#{month}"), xhr: true
    assert_response :unauthorized
  end

  # monthパラメータが必須であることを検証
  test "calendar requires month parameter" do
    get api("/meals/calendar"), xhr: true, headers: @headers
    assert_response :bad_request

    json = res_body
    assert json.key?("error")
  end

  # monthパラメータの形式を検証
  test "calendar validates month format" do
    get api("/meals/calendar?month=invalid"), xhr: true, headers: @headers
    assert_response :bad_request
  end

  # monthパラメータの範囲を検証
  test "calendar validates month range" do
    get api("/meals/calendar?month=2025-13"), xhr: true, headers: @headers
    assert_response :bad_request

    get api("/meals/calendar?month=2025-00"), xhr: true, headers: @headers
    assert_response :bad_request
  end

  # 食事のない月で空のデータが返されることを検証
  test "calendar returns empty for month without meals" do
    future_month = (Date.today >> 6).strftime("%Y-%m")

    get api("/meals/calendar?month=#{future_month}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal future_month, json["month"]
    # 食事がない月でも days は存在するが空かもしれない
    assert json.key?("days")
  end
end
