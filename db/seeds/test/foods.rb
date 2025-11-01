# テスト用食品データ
foods_data = [
  {
    food_code: "11001",
    index_number: "1001",
    name: "鶏むね肉（皮なし）",
    calories: 108,
    protein: 22.3,
    fat: 1.5,
    carbohydrate: 0.0
  },
  {
    food_code: "11002",
    index_number: "1002",
    name: "白米",
    calories: 168,
    protein: 2.5,
    fat: 0.3,
    carbohydrate: 37.1
  },
  {
    food_code: "11003",
    index_number: "1003",
    name: "リンゴ",
    calories: 54,
    protein: 0.2,
    fat: 0.1,
    carbohydrate: 14.6
  },
  {
    food_code: "11004",
    index_number: "1004",
    name: "サーモン",
    calories: 138,
    protein: 20.0,
    fat: 6.0,
    carbohydrate: 0.0
  },
  {
    food_code: "11005",
    index_number: "1005",
    name: "ブロッコリー",
    calories: 33,
    protein: 4.3,
    fat: 0.5,
    carbohydrate: 5.2
  }
]

foods_data.each do |data|
  food = Food.find_or_initialize_by(index_number: data[:index_number])

  if food.new_record?
    food.assign_attributes(data)
    food.save!
  end
end

puts "test foods = #{Food.count}"
