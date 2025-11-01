require "test_helper"

class Api::V1::FoodsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = active_user
    @token = @user.encode_access_token
    @headers = auth(@token.token)

    # テスト用の食品データ
    @chicken = Food.create!(
      food_code: "11001",
      index_number: 1001,
      name: "鶏むね肉（皮なし）",
      calories: 108,
      protein: 22.3,
      fat: 1.5,
      carbohydrate: 0.0
    )

    @rice = Food.create!(
      food_code: "11002",
      index_number: 1002,
      name: "白米",
      calories: 168,
      protein: 2.5,
      fat: 0.3,
      carbohydrate: 37.1
    )

    @apple = Food.create!(
      food_code: "11003",
      index_number: 1003,
      name: "リンゴ",
      calories: 54,
      protein: 0.2,
      fat: 0.1,
      carbohydrate: 14.6
    )

    @apple_juice = Food.create!(
      food_code: "11004",
      index_number: 1004,
      name: "リンゴジュース",
      calories: 44,
      protein: 0.1,
      fat: 0.0,
      carbohydrate: 11.5
    )

    # 栄養情報なしの食品
    @unknown = Food.create!(
      food_code: "11005",
      index_number: 1005,
      name: "未知の食品",
      calories: nil,
      protein: nil,
      fat: nil,
      carbohydrate: nil
    )
  end

  # GET /api/v1/foods
  test "index returns foods matching query" do
    get api("/foods?q=#{CGI.escape('鶏')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert json.key?("foods")

    foods = json["foods"]
    assert_kind_of Array, foods
    assert foods.length >= 1

    chicken = foods.find { |f| f["id"] == @chicken.id }
    assert_not_nil chicken
    assert_equal "鶏むね肉（皮なし）", chicken["name"]
    assert_equal "108.0", chicken["calories"].to_s
    assert_equal "22.3", chicken["protein"].to_s
  end

  test "index requires authentication" do
    get api("/foods?q=#{CGI.escape('鶏')}"), xhr: true
    assert_response :unauthorized
  end

  test "index returns empty array for blank query" do
    get api("/foods?q="), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal [], json["foods"]
  end

  test "index returns empty array when no query parameter" do
    get api("/foods"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal [], json["foods"]
  end

  test "index returns multiple matching foods" do
    get api("/foods?q=#{CGI.escape('リンゴ')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    foods = json["foods"]
    assert foods.length >= 2

    names = foods.map { |f| f["name"] }
    assert_includes names, "リンゴ"
    assert_includes names, "リンゴジュース"
  end

  test "index returns only foods with nutrition data" do
    get api("/foods?q=#{CGI.escape('食品')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    foods = json["foods"]

    # 未知の食品（栄養情報なし）は含まれない
    ids = foods.map { |f| f["id"] }
    assert_not_includes ids, @unknown.id
  end

  test "index limits results to 20 items" do
    # 21個の食品を作成
    21.times do |i|
      Food.create!(
        food_code: "test#{i}",
        index_number: 2000 + i,
        name: "テスト食品#{i}",
        calories: 100
      )
    end

    get api("/foods?q=#{CGI.escape('テスト')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    foods = json["foods"]
    assert foods.length <= 20
  end

  test "index returns correct food attributes" do
    get api("/foods?q=#{CGI.escape('白米')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    rice = json["foods"].find { |f| f["id"] == @rice.id }

    assert_not_nil rice
    assert_equal @rice.id, rice["id"]
    assert_equal "白米", rice["name"]
    assert_equal "168.0", rice["calories"].to_s
    assert_equal "2.5", rice["protein"].to_s
    assert_equal "0.3", rice["fat"].to_s
    assert_equal "37.1", rice["carbohydrate"].to_s

    # food_codeやindex_numberは含まれない（セキュリティ）
    assert_not rice.key?("food_code")
    assert_not rice.key?("index_number")
  end

  test "index does not return foods without nutrition" do
    # 栄養情報のない食品をもう1つ作成
    food_no_nutrition = Food.create!(
      food_code: "99999",
      index_number: 99999,
      name: "栄養情報なし",
      calories: nil,
      protein: nil,
      fat: nil,
      carbohydrate: nil
    )

    get api("/foods?q=#{CGI.escape('栄養')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    ids = json["foods"].map { |f| f["id"] }
    assert_not_includes ids, food_no_nutrition.id
  end

  test "index partial match search" do
    get api("/foods?q=#{CGI.escape('む')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    names = json["foods"].map { |f| f["name"] }
    assert_includes names, "鶏むね肉（皮なし）"
  end

  test "index returns foods for user" do
    # 他のユーザーでも同じ食品データベースにアクセスできる
    other_user = User.create!(
      name: "Other User",
      email: "other@example.com",
      password: "password",
      activated: true
    )
    other_token = other_user.encode_access_token
    other_headers = auth(other_token.token)

    get api("/foods?q=#{CGI.escape('鶏')}"), xhr: true, headers: other_headers
    assert_response :success

    json = res_body
    assert json["foods"].length >= 1
  end

  test "index handles special characters in query" do
    food_special = Food.create!(
      food_code: "12345",
      index_number: 12345,
      name: "食品（特別）",
      calories: 100
    )

    get api("/foods?q=#{CGI.escape('（')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    names = json["foods"].map { |f| f["name"] }
    assert_includes names, "食品（特別）"
    assert_includes names, "鶏むね肉（皮なし）"
  end

  test "index handles SQL injection attempts" do
    malicious_query = "'; DROP TABLE foods; --"

    assert_nothing_raised do
      get api("/foods?q=#{CGI.escape(malicious_query)}"), xhr: true, headers: @headers
    end

    assert_response :success

    # テーブルがまだ存在することを確認
    assert Food.count >= 5
  end

  test "index returns empty for no matches" do
    get api("/foods?q=#{CGI.escape('存在しない食品名XYZ')}"), xhr: true, headers: @headers
    assert_response :success

    json = res_body
    assert_equal [], json["foods"]
  end
end
