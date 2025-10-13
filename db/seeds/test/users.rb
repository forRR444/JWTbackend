10.times do |n|
  name = "test_user#{n}"
  email = "test_user#{n}@example.com"
  user = User.find_or_initialize_by(email: email, activated: true)

  if user.new_record?
    user.name = name
    user.password = "password"
    user.activated = true
    user.save!
  end
end

puts "test users = #{User.count}"
