class Api::V1::UsersController < ApplicationController
  # JWTトークンの持ち主かどうかを確認（未ログインは401）
  before_action :authenticate_user, only: [:me]

  def create
    user = User.new(user_params)
    # 最小構成：メール認証を省略して即有効化
    user.activated = true

    if user.save
      # ログイン時と同じレスポンスを返す（即サインイン扱い）
      set_refresh_token_cookie_for(user)
      access = user.encode_access_token
      render json: {
        token: access.token,
        expires: access.payload[:exp],
        user:  user.response_json
      }, status: :created
    else
      render status: :unprocessable_entity, json: {
        status: 422,
        error: user.errors.full_messages.join(", ")
      }
    end
  end

  # 現在ログイン中のユーザー情報を返す
  def me
    # アプリの既存仕様に合わせて共通レスポンスを返す
    render json: current_user.response_json, status: :ok
  end

  private

    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    # refresh_token を Cookie に設定（AuthTokenController と同等の挙動）
    def set_refresh_token_cookie_for(user)
      refresh = user.encode_refresh_token
      # jti をユーザーに記憶（リフレッシュ無効化/検証で使用）
      user.remember(refresh.payload[:jti])

      cookies[UserAuth.session_key] = {
        value:   refresh.token,
        expires: Time.at(refresh.payload[:exp]),
        httponly: true,
        secure: Rails.env.production?, # 本番は secure
        same_site: :lax
      }
    end
end
