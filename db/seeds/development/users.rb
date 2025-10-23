# テストアカウント（フロントエンドのテストログイン用）
test_user = User.find_or_initialize_by(email: "test@example.com", activated: true)
if test_user.new_record?
  test_user.name = "テストユーザー"
  test_user.password = "password"
  test_user.save!
  puts "Created test user: test@example.com / password"
end

10.times do |n|
  name = "user#{n}"
  email = "#{name}@example.com"
  # find_by(email: email, activated: true)
  # オブジェクトが存在する => 取得
  # オブジェクトが存在しない => 新規作成
  user = User.find_or_initialize_by(email: email, activated: true)

  if user.new_record?
    user.name = name
    user.password = "password"
    user.save!
  end
end

puts "Development users = #{User.count}"
