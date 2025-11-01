require "test_helper"

class Api::V1::UsersControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = active_user
    @token = @user.encode_access_token
    @headers = auth(@token.token)
    @session_key = UserAuth.session_key.to_s
  end

  # POST /api/v1/users - 新規ユーザー登録のテスト
  # 新規ユーザーが正しく登録できることを検証
  test "create registers a new user successfully" do
    user_params = {
      user: {
        name: "New User",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_difference("User.count", 1) do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :created

    json = res_body
    # レスポンスにトークンとユーザー情報が含まれる
    assert json.key?("token")
    assert json.key?("expires")
    assert json.key?("user")

    # ユーザー情報の検証
    assert_equal "New User", json["user"]["name"]
    assert_not_nil json["user"]["id"]

    # ユーザーがactivatedになっている
    new_user = User.find(json["user"]["id"])
    assert new_user.activated

    # リフレッシュトークンがcookieにセットされている
    assert_not_nil cookies[@session_key]
  end

  # 名前の必須検証を確認
  test "create validates name presence" do
    user_params = {
      user: {
        name: "",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert json.key?("error")
    assert_match(/名前/, json["error"])
  end

  # 名前の長さ制限を検証
  test "create validates name length" do
    user_params = {
      user: {
        name: "a" * 31, # 30文字制限を超える
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert_match(/名前/, json["error"])
  end

  # メールアドレスの必須検証を確認
  test "create validates email presence" do
    user_params = {
      user: {
        name: "Test User",
        email: "",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert_match(/メールアドレス/, json["error"])
  end

  # メールアドレスの形式を検証
  test "create validates email format" do
    invalid_emails = [ "invalid", "test@", "@example.com", "test@.com" ]

    invalid_emails.each do |invalid_email|
      user_params = {
        user: {
          name: "Test User",
          email: invalid_email,
          password: "password123",
          password_confirmation: "password123"
        }
      }

      assert_no_difference("User.count") do
        post api("/users"), xhr: true, params: user_params, as: :json
      end

      assert_response :unprocessable_entity
    end
  end

  # アクティブユーザーのメールアドレス一意性を検証
  test "create validates email uniqueness for active users" do
    # 既存のアクティブユーザーと同じメールアドレス
    user_params = {
      user: {
        name: "Duplicate User",
        email: @user.email, # 既存ユーザーのメール
        password: "password123",
        password_confirmation: "password123"
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert_match(/メールアドレス/, json["error"])
  end

  # パスワードの必須検証を確認
  test "create validates password presence" do
    user_params = {
      user: {
        name: "Test User",
        email: "test@example.com",
        password: "",
        password_confirmation: ""
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert_match(/パスワード/, json["error"])
  end

  # パスワードの最小文字数を検証
  test "create validates password minimum length" do
    user_params = {
      user: {
        name: "Test User",
        email: "test@example.com",
        password: "pass123", # 7文字（8文字未満）
        password_confirmation: "pass123"
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert_match(/パスワード/, json["error"])
  end

  # パスワードの形式を検証
  test "create validates password format" do
    invalid_passwords = [ "pass word", "pass@word", "パスワード123" ]

    invalid_passwords.each do |invalid_password|
      user_params = {
        user: {
          name: "Test User",
          email: "unique#{rand(1000)}@example.com",
          password: invalid_password,
          password_confirmation: invalid_password
        }
      }

      assert_no_difference("User.count") do
        post api("/users"), xhr: true, params: user_params, as: :json
      end

      assert_response :unprocessable_entity
    end
  end

  # パスワード確認の一致を検証
  test "create validates password confirmation match" do
    user_params = {
      user: {
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "different123"
      }
    }

    assert_no_difference("User.count") do
      post api("/users"), xhr: true, params: user_params, as: :json
    end

    assert_response :unprocessable_entity

    json = res_body
    assert_match(/パスワード/, json["error"])
  end

  # メールアドレスが小文字化されることを検証
  test "create downcases email" do
    user_params = {
      user: {
        name: "Test User",
        email: "UPPERCASE@EXAMPLE.COM",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    post api("/users"), xhr: true, params: user_params, as: :json
    assert_response :created

    json = res_body
    new_user = User.find(json["user"]["id"])
    assert_equal "uppercase@example.com", new_user.email
  end

  # 正しい有効期限のアクセストークンが発行されることを検証
  test "create issues access token with correct expiration" do
    user_params = {
      user: {
        name: "Token Test User",
        email: "tokentest@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    post api("/users"), xhr: true, params: user_params, as: :json
    assert_response :created

    json = res_body
    assert_not_nil json["token"]
    assert_not_nil json["expires"]

    # トークンの有効期限が未来であることを確認
    assert json["expires"] > Time.current.to_i
  end

  # XHRリクエストが必要であることを検証
  test "create requires xhr request" do
    user_params = {
      user: {
        name: "Test User",
        email: "test@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }

    # xhr: falseでリクエスト
    post api("/users"), xhr: false, params: user_params, as: :json
    assert_response :forbidden
  end

  # GET /api/v1/me - 現在のユーザー情報取得
  # 現在のユーザー情報が取得できることを検証
  test "me returns current user information" do
    get api("/me"), xhr: true, headers: @headers
    assert_response :ok

    json = res_body
    assert_equal @user.id, json["id"]
    assert_equal @user.name, json["name"]
    assert json.key?("target_calories")
    assert json.key?("target_protein")
    assert json.key?("target_fat")
    assert json.key?("target_carbohydrate")
  end

  # 認証が必要であることを検証
  test "me requires authentication" do
    get api("/me"), xhr: true
    assert_response :unauthorized
  end

  # 機密情報が公開されないことを検証
  test "me does not expose sensitive information" do
    get api("/me"), xhr: true, headers: @headers
    assert_response :ok

    json = res_body
    # パスワードやメールアドレスは含まれない
    assert_not json.key?("password")
    assert_not json.key?("password_digest")
    assert_not json.key?("email")
    assert_not json.key?("refresh_jti")
    assert_not json.key?("activated")
  end

  # 有効期限切れトークンで401を返すことを検証
  test "me returns 401 for expired token" do
    # トークンの有効期限を過ぎた状態をシミュレート
    travel_to(UserAuth.access_token_lifetime.from_now + 1.second) do
      get api("/me"), xhr: true, headers: @headers
      assert_response :unauthorized
    end
  end

  # 無効なトークンで401を返すことを検証
  test "me returns 401 for invalid token" do
    invalid_headers = auth("invalid.token.here")
    get api("/me"), xhr: true, headers: invalid_headers
    assert_response :unauthorized
  end

  # PUT /api/v1/users/goals - 栄養目標の更新
  # ユーザーの栄養目標が更新できることを検証
  test "update_goals updates user nutrition goals" do
    goal_params = {
      user: {
        target_calories: 2000,
        target_protein: 150,
        target_fat: 60,
        target_carbohydrate: 250
      }
    }

    put api("/users/goals"), xhr: true, headers: @headers, params: goal_params, as: :json
    assert_response :ok

    json = res_body
    assert_equal 2000, json["target_calories"]
    assert_equal "150.0", json["target_protein"].to_s
    assert_equal "60.0", json["target_fat"].to_s
    assert_equal "250.0", json["target_carbohydrate"].to_s

    # NutritionGoalとして保存されている
    @user.reload
    current_goal = @user.current_goal
    assert_not_nil current_goal
    assert_equal 2000, current_goal.target_calories
    assert_equal 150, current_goal.target_protein.to_i
    assert_equal 60, current_goal.target_fat.to_i
    assert_equal 250, current_goal.target_carbohydrate.to_i
    assert_equal Date.today, current_goal.start_date
    assert_nil current_goal.end_date
  end

  # 部分的な目標更新ができることを検証
  test "update_goals can update partial goals" do
    # カロリーだけを更新
    goal_params = {
      user: {
        target_calories: 1800
      }
    }

    put api("/users/goals"), xhr: true, headers: @headers, params: goal_params, as: :json
    assert_response :ok

    json = res_body
    assert_equal 1800, json["target_calories"]
  end

  # nil値を受け入れることを検証
  test "update_goals accepts nil values" do
    # 目標値をクリア
    goal_params = {
      user: {
        target_calories: nil,
        target_protein: nil,
        target_fat: nil,
        target_carbohydrate: nil
      }
    }

    put api("/users/goals"), xhr: true, headers: @headers, params: goal_params, as: :json
    assert_response :ok

    @user.reload
    current_goal = @user.current_goal
    assert_not_nil current_goal
    assert_nil current_goal.target_calories
    assert_nil current_goal.target_protein
    assert_nil current_goal.target_fat
    assert_nil current_goal.target_carbohydrate
  end

  # 小数値を受け入れることを検証
  test "update_goals accepts decimal values" do
    goal_params = {
      user: {
        target_protein: 150.5,
        target_fat: 60.3,
        target_carbohydrate: 250.8
      }
    }

    put api("/users/goals"), xhr: true, headers: @headers, params: goal_params, as: :json
    assert_response :ok

    json = res_body
    assert_equal "150.5", json["target_protein"].to_s
    assert_equal "60.3", json["target_fat"].to_s
    assert_equal "250.8", json["target_carbohydrate"].to_s
  end

  # 認証が必要であることを検証
  test "update_goals requires authentication" do
    goal_params = {
      user: {
        target_calories: 2000
      }
    }

    put api("/users/goals"), xhr: true, params: goal_params, as: :json
    assert_response :unauthorized

    # ユーザーの目標値は変更されていない
    # (変更なしを確認するため、何もアサートしない)
  end

  # 他のフィールドの更新を許可しないことを検証
  test "update_goals does not allow updating other fields" do
    # nameやemailなどの更新を試みる
    malicious_params = {
      user: {
        target_calories: 2000,
        name: "Hacked Name",
        email: "hacked@example.com",
        admin: true
      }
    }

    original_name = @user.name
    original_email = @user.email

    put api("/users/goals"), xhr: true, headers: @headers, params: malicious_params, as: :json
    assert_response :ok

    # name、email、adminは変更されていない
    @user.reload
    assert_equal original_name, @user.name
    assert_equal original_email, @user.email
    assert_not @user.admin

    # target_caloriesのみ変更されている（NutritionGoalとして）
    current_goal = @user.current_goal
    assert_equal 2000, current_goal.target_calories
  end

  # 有効期限切れトークンで401を返すことを検証
  test "update_goals returns 401 for expired token" do
    goal_params = {
      user: {
        target_calories: 2000
      }
    }

    travel_to(UserAuth.access_token_lifetime.from_now + 1.second) do
      put api("/users/goals"), xhr: true, headers: @headers, params: goal_params, as: :json
      assert_response :unauthorized
    end
  end

  # XHRリクエストが必要であることを検証
  test "update_goals requires xhr request" do
    goal_params = {
      user: {
        target_calories: 2000
      }
    }

    put api("/users/goals"), xhr: false, headers: @headers, params: goal_params, as: :json
    assert_response :forbidden
  end

  # 更新されたユーザーデータが返されることを検証
  test "update_goals returns updated user data" do
    # 既存の目標を作成
    @user.nutrition_goals.create!(
      target_calories: 1500,
      target_protein: 100,
      target_fat: 50,
      target_carbohydrate: 200,
      start_date: 1.month.ago
    )

    goal_params = {
      user: {
        target_calories: 2500,
        target_protein: 200
      }
    }

    put api("/users/goals"), xhr: true, headers: @headers, params: goal_params, as: :json
    assert_response :ok

    json = res_body
    assert_equal 2500, json["target_calories"]
    assert_equal "200.0", json["target_protein"].to_s
    # 新しく設定された値のみが含まれる（部分更新）
    # fat, carbohydrateは指定されていないのでnil
  end

  # 同じ日に複数回更新した場合、最新の値が返されることを検証
  test "update_goals multiple times on same day returns latest values" do
    # 1回目の更新
    first_params = {
      user: {
        target_calories: 2000,
        target_protein: 100
      }
    }
    put api("/users/goals"), xhr: true, headers: @headers, params: first_params, as: :json
    assert_response :ok

    json = res_body
    assert_equal 2000, json["target_calories"]
    assert_equal "100.0", json["target_protein"].to_s

    # 2回目の更新（同じ日）
    second_params = {
      user: {
        target_calories: 2500,
        target_protein: 150
      }
    }
    put api("/users/goals"), xhr: true, headers: @headers, params: second_params, as: :json
    assert_response :ok

    json = res_body
    assert_equal 2500, json["target_calories"]
    assert_equal "150.0", json["target_protein"].to_s

    # データベースを確認
    @user.reload
    current_goal = @user.current_goal
    assert_not_nil current_goal
    assert_equal 2500, current_goal.target_calories
    assert_equal 150, current_goal.target_protein.to_i
  end
end
