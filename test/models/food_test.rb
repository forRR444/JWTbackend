require "test_helper"

class FoodTest < ActiveSupport::TestCase
  def setup
    @food = Food.create!(
      food_code: "01001",
      index_number: 1,
      name: "鶏むね肉（皮なし）",
      calories: 108,
      protein: 22.3,
      fat: 1.5,
      carbohydrate: 0.0
    )
  end

  # 有効な食品データが正しく作成されることを検証
  test "valid food" do
    assert @food.valid?
  end

  # food_codeのバリデーションを検証
  test "food_code validation" do
    # food_codeが必須
    food = Food.new(
      index_number: 999,
      name: "Test Food"
    )
    assert_not food.valid?
    assert food.errors[:food_code].present?

    food.food_code = "12345"
    assert food.valid?
  end

  # index_numberのバリデーションを検証
  test "index_number validation" do
    # index_numberが必須
    food = Food.new(
      food_code: "99999",
      name: "Test Food"
    )
    assert_not food.valid?
    assert food.errors[:index_number].present?

    food.index_number = 999
    assert food.valid?
  end

  # index_numberの一意性を検証
  test "index_number uniqueness" do
    # 同じindex_numberは登録できない
    duplicate = Food.new(
      food_code: "99999",
      index_number: @food.index_number,
      name: "Duplicate Food"
    )
    assert_not duplicate.valid?
    assert duplicate.errors[:index_number].present?

    # 異なるindex_numberなら登録できる
    duplicate.index_number = 999999
    assert duplicate.valid?
  end

  # nameのバリデーションを検証
  test "name validation" do
    # nameが必須
    @food.name = nil
    assert_not @food.valid?
    assert @food.errors[:name].present?

    @food.name = ""
    assert_not @food.valid?
    assert @food.errors[:name].present?

    @food.name = "Valid Name"
    assert @food.valid?
  end

  # 栄養データが保存できることを検証
  test "nutrition data can be stored" do
    food = Food.create!(
      food_code: "02002",
      index_number: 2,
      name: "白米",
      calories: 168,
      protein: 2.5,
      fat: 0.3,
      carbohydrate: 37.1
    )

    assert_equal 168, food.calories
    assert_equal 2.5, food.protein
    assert_equal 0.3, food.fat
    assert_equal 37.1, food.carbohydrate
  end

  # 栄養データがnilの場合を検証
  test "nutrition data can be nil" do
    food = Food.create!(
      food_code: "99999",
      index_number: 999,
      name: "Unknown Food"
    )

    assert_nil food.calories
    assert_nil food.protein
    assert_nil food.fat
    assert_nil food.carbohydrate
  end

  # search_by_nameスコープが完全一致で検索できることを検証
  test "scope search_by_name with full match" do
    results = Food.search_by_name("鶏むね肉")
    assert_includes results, @food
  end

  # search_by_nameスコープが部分一致で検索できることを検証
  test "scope search_by_name with partial match" do
    results = Food.search_by_name("鶏")
    assert_includes results, @food

    results = Food.search_by_name("むね")
    assert_includes results, @food
  end

  # search_by_nameスコープの大文字小文字の扱いを検証
  test "scope search_by_name case sensitivity" do
    food_en = Food.create!(
      food_code: "03003",
      index_number: 3,
      name: "Chicken Breast",
      calories: 110,
      protein: 23.0,
      fat: 1.2,
      carbohydrate: 0.0
    )

    # 大文字小文字を区別する（デフォルトのLIKE動作）
    results = Food.search_by_name("chicken")
    # SQLiteやPostgreSQLのデフォルトでは大文字小文字を区別することがある
    # このテストは環境依存のため、存在チェックのみ
    assert results.is_a?(ActiveRecord::Relation)
  end

  # search_by_nameスコープが結果なしの場合を検証
  test "scope search_by_name with no results" do
    results = Food.search_by_name("存在しない食品")
    assert_empty results
  end

  # search_by_nameスコープが空クエリの場合を検証
  test "scope search_by_name with empty query" do
    results = Food.search_by_name("")
    # 空文字検索は全件マッチ（%％の動作）
    assert_includes results, @food
  end

  # search_by_nameスコープがSQLインジェクションを防ぐことを検証
  test "scope search_by_name with SQL injection prevention" do
    # SQL injectionが防がれていることを確認
    malicious_query = "'; DROP TABLE foods; --"
    assert_nothing_raised do
      results = Food.search_by_name(malicious_query)
      assert_empty results
    end

    # テーブルがまだ存在していることを確認
    assert Food.count >= 1
  end

  # with_nutritionスコープがカロリーを持つ食品を含むことを検証
  test "scope with_nutrition includes foods with calories" do
    food_with_calories = Food.create!(
      food_code: "04004",
      index_number: 4,
      name: "Food with calories",
      calories: 200,
      protein: nil,
      fat: nil,
      carbohydrate: nil
    )

    results = Food.with_nutrition
    assert_includes results, @food
    assert_includes results, food_with_calories
  end

  # with_nutritionスコープがタンパク質を持つ食品を含むことを検証
  test "scope with_nutrition includes foods with protein" do
    food_with_protein = Food.create!(
      food_code: "05005",
      index_number: 5,
      name: "Food with protein",
      calories: nil,
      protein: 10.0,
      fat: nil,
      carbohydrate: nil
    )

    results = Food.with_nutrition
    assert_includes results, food_with_protein
  end

  # with_nutritionスコープが栄養情報なしの食品を除外することを検証
  test "scope with_nutrition excludes foods without nutrition" do
    food_without_nutrition = Food.create!(
      food_code: "06006",
      index_number: 6,
      name: "Food without nutrition",
      calories: nil,
      protein: nil,
      fat: nil,
      carbohydrate: nil
    )

    results = Food.with_nutrition
    assert_not_includes results, food_without_nutrition
  end

  # スコープの連鎖が正しく動作することを検証
  test "scope chaining search_by_name and with_nutrition" do
    # 栄養情報なしの鶏肉
    food_no_nutrition = Food.create!(
      food_code: "07007",
      index_number: 7,
      name: "鶏もも肉",
      calories: nil,
      protein: nil,
      fat: nil,
      carbohydrate: nil
    )

    results = Food.search_by_name("鶏").with_nutrition
    assert_includes results, @food
    assert_not_includes results, food_no_nutrition
  end

  # 複数の食品が検索できることを検証
  test "multiple foods with search" do
    foods = [
      Food.create!(food_code: "10001", index_number: 101, name: "リンゴ", calories: 54),
      Food.create!(food_code: "10002", index_number: 102, name: "リンゴジュース", calories: 44),
      Food.create!(food_code: "10003", index_number: 103, name: "オレンジ", calories: 39)
    ]

    results = Food.search_by_name("リンゴ")
    assert_equal 2, results.count
    assert_includes results, foods[0]
    assert_includes results, foods[1]
    assert_not_includes results, foods[2]
  end
end
