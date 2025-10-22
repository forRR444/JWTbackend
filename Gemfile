source "https://rubygems.org"

gem "rails", "~> 8.1.0"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "bootsnap", require: false
gem "kamal", require: false
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

# JWT認証用Gem
gem "bcrypt"
gem "rack-cors"
# jwt Doc: https://rubygems.org/gems/jwt
gem 'jwt', '~> 3.1', '>= 3.1.2'

group :development, :test do
  gem "dotenv-rails"
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # テスト結果を色付けする
  gem 'minitest-reporters', '~> 1.1', '>= 1.1.11'
end
