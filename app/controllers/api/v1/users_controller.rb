class Api::V1::UsersController < ApplicationController
  # JWTトークンの持ち主かどうかを確認（未ログインは401）
  before_action :authenticate_user

  # 現在ログイン中のユーザー情報を返す
  def me
    # アプリの既存仕様に合わせて共通レスポンスを返す
    render json: current_user.response_json, status: :ok
  end
end
