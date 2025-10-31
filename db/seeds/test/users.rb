# frozen_string_literal: true

10.times do |n|
  name = "test_user#{n}"
  email = "test_user#{n}@example.com"
  user = User.find_or_initialize_by(email: email, activated: true)

  next unless user.new_record?

  user.name = name
  user.password = "password"
  user.activated = true
  user.save!
end

puts "test users = #{User.count}"
