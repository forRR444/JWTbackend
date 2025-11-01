class Api::V1::UsersController < ApplicationController
  include TokenCookieHandler

  # アクセス前にログイン済みか確認
  before_action :authenticate_user, only: [ :me, :update_goals ]

  # 新規ユーザーを登録し、自動的にログイン状態にする
  def create
    user = build_new_user
    if user.save
      sign_in_user(user) # リフレッシュトークンをセット
      render json: user_registration_response(user), status: :created
    else
      render_user_errors(user)
    end
  end

  # 現在ログイン中のユーザー情報を返す
  def me
    render json: current_user.response_json, status: :ok
  end

  # ユーザーの栄養目標値を更新
  def update_goals
    # 既存の有効な目標を終了
    current_goal = current_user.current_goal
    current_goal&.deactivate!

    # 新しい目標を作成
    @goal = current_user.nutrition_goals.build(goal_params)
    @goal.start_date = Date.today

    if @goal.save
      # 関連付けを再読み込みして最新の目標を取得
      current_user.nutrition_goals.reload
      render json: current_user.response_json, status: :ok
    else
      render status: :unprocessable_entity, json: {
        status: 422,
        error: @goal.errors.full_messages.join(", ")
      }
    end
  end

  private
    # 新規ユーザーオブジェクトを構築（メール認証は未実装）
    def build_new_user
      user = User.new(user_params)
      user.activated = true
      user
    end

    # ユーザーをサインインさせる（リフレッシュトークンをセット）
    def sign_in_user(user)
      set_refresh_token_cookie(user)
    end

    # ユーザー登録時のレスポンスを構築
    def user_registration_response(user)
      access = user.encode_access_token
      {
        token: access.token,
        expires: access.payload[:exp],
        user: user.response_json
      }
    end

    # ユーザーエラーをレンダリング
    def render_user_errors(user)
      render status: :unprocessable_entity, json: {
        # バリデーションエラーなどをまとめて返す
        status: 422,
        error: user.errors.full_messages.join(", ")
      }
    end

    # ユーザー登録時の許可パラメータ
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    # 栄養目標更新時の許可パラメータ
    def goal_params
      params.require(:user).permit(
        :target_calories,
        :target_protein,
        :target_fat,
        :target_carbohydrate
      )
    end
end
