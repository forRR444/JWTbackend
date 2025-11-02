# frozen_string_literal: true

source "https://rubygems.org"

gem "bootsnap", require: false
gem "kamal", require: false
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"
# Docker環境では複数データベース設定が必要なため、シンプルな設定を使用
# gem "solid_cable"
# gem "solid_cache"
# gem "solid_queue"
gem "thruster", require: false
gem "tzinfo-data", platforms: %i[windows jruby]

# JWT認証用Gem
gem "bcrypt"
gem "rack-cors"
# jwt Doc: https://rubygems.org/gems/jwt
gem "jwt", "~> 3.1", ">= 3.1.2"

# Excel読み込み用Gem
gem "csv"
gem "roo", "~> 2.10"

group :development, :test do
  gem "brakeman", require: false
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "dotenv-rails"
  gem "rails-erd"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  # テスト結果を色付けする
  gem "minitest-reporters", "~> 1.1", ">= 1.1.11"
end
