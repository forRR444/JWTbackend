class Api::V1::UsersController < ApplicationController
  include TokenCookieHandler

  # JWTトークンの持ち主かどうかを確認（未ログインは401）
  before_action :authenticate_user, only: [ :me ]

  # POST /api/v1/users
  # ユーザー登録
  def create
    user = User.new(user_params)
    # 最小構成：メール認証を省略して即有効化
    user.activated = true

    if user.save
      # ログイン時と同じレスポンスを返す（即サインイン扱い）
      set_refresh_token_cookie(user)
      access = user.encode_access_token
      render json: {
        token: access.token,
        expires: access.payload[:exp],
        user: user.response_json
      }, status: :created
    else
      render status: :unprocessable_entity, json: {
        status: 422,
        error: user.errors.full_messages.join(", ")
      }
    end
  end

  # GET /api/v1/me
  # 現在ログイン中のユーザー情報を返す
  def me
    render json: current_user.response_json, status: :ok
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
