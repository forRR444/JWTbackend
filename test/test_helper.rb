ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# gem minitest-reportersセットアップ
require "minitest/reporters"
Minitest::Reporters.use!

module ActiveSupport
  class TestCase
    # プロセスが分岐した直後に呼ばれる
    parallelize_setup do |worker|
      # seedデータの読み込み
      load "#{Rails.root}/db/seeds.rb"
    end

    # 並列テストの有効化・無効化
    parallelize(workers: :number_of_processors)

    # アクティブなユーザーを返す
    def active_user
      User.find_by(activated: true) ||
      User.create!(
      name: "Test User",
      email: "testuser@example.com",
      password: "password",
      activated: true
    )
    end

    # api path
    def api(path = "/")
      "/api/v1#{path}"
    end

    # 認可ヘッダ
    def auth(token)
      { Authorization: "Bearer #{token}" }
    end

    # 引数のparamsでログインを行う
    def login(params)
      post api("/auth_token"), xhr: true, params: params
    end

    # ログアウトapi
    def logout
      delete api("/auth_token"), xhr: true
    end

    # レスポンスJSONをハッシュで返す
    def res_body
      @response.parsed_body || {}
    end

    # UserAuthの設定
    UserAuth.token_issuer   = "rails8-example"
    UserAuth.token_audience = "rails8-example-client"
    UserAuth.token_signature_algorithm = "HS256"
    UserAuth.access_token_lifetime = 30.minutes
  end
end
