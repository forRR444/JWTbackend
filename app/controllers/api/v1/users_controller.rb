class Api::V1::UsersController < ApplicationController
  include TokenCookieHandler

  before_action :authenticate_user, only: [ :me, :update_goals ]

  # POST /api/v1/users
  # 新規ユーザーを登録し、自動的にログイン状態にする
  def create
    user = build_new_user

    if user.save
      sign_in_user(user)
      render json: user_registration_response(user), status: :created
    else
      render_user_errors(user)
    end
  end

  # GET /api/v1/me
  # 現在ログイン中のユーザー情報を返す
  def me
    render json: current_user.response_json, status: :ok
  end

  # PUT /api/v1/users/goals
  # ユーザーの栄養目標値を更新
  def update_goals
    if current_user.update(goal_params)
      render json: current_user.response_json, status: :ok
    else
      render_user_errors(current_user)
    end
  end

  private

  # 新規ユーザーオブジェクトを構築（メール認証は省略して即有効化）
  def build_new_user
    user = User.new(user_params)
    user.activated = true
    user
  end

  # ユーザーをサインインさせる（Refresh Tokenをセット）
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
