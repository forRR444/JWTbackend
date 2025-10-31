# frozen_string_literal: true

module Api
  module V1
    class AuthTokenController < ApplicationController
      include UserSessionizeService # セッションからユーザーを取得する処理
      include TokenCookieHandler # Cookieでリフレッシュトークンを管理する処理

      # refresh_tokenのUserNotFoundErrorが発生した場合は404を返す
      rescue_from UserAuth.not_found_exception_class, with: :not_found
      # refresh_tokenのInvalidJtiErrorが発生した場合はカスタムエラーを返す
      rescue_from JWT::InvalidJtiError, with: :invalid_jti

      # userのログイン情報を確認する
      before_action :authenticate, only: [:create]
      # 処理前にsessionを削除する
      before_action :delete_session, only: [:create]
      # session_userを取得、存在しない場合は401を返す
      before_action :sessionize_user, only: %i[refresh destroy]

      # ログイン
      def create
        @user = login_user
        set_refresh_token_cookie(@user) # Cookieにリフレッシュトークンを保存
        render json: login_response # アクセストークンを返す
      end

      # リフレッシュ
      def refresh
        @user = session_user
        set_refresh_token_cookie(@user) # 新しいリフレッシュトークンを設定
        render json: login_response # 新しいアクセストークンを返す
      end

      # ログアウト
      def destroy
        session_user.forget # DBのjti削除
        delete_refresh_token_cookie # Cookie削除
        head :ok
      end

      private

      # email から有効なユーザーを探す
      def login_user
        @login_user ||= User.find_by_activated(auth_params[:email])
      end

      # ユーザーが存在しないかパスワード不一致なら404を返す
      def authenticate
        unless login_user.present? &&
               login_user.authenticate(auth_params[:password])
          raise UserAuth.not_found_exception_class
        end
      end

      # ログイン時のレスポンス
      def login_response
        access = @user.encode_access_token
        {
          token: access.token, # アクセストークン文字列
          expires: access.payload[:exp], # 有効期限
          user: @user.response_json(sub: access.payload[:sub]) # ユーザー情報
        }
      end

      # 404レスポンス
      # Doc: https://gist.github.com/mlanett/a31c340b132ddefa9cca
      def not_found
        render status: :not_found, json: {
          status: 404,
          error: "メールアドレスまたはパスワードが正しくありません。"
        }
      end

      # 401レスポンス（jti無効時）
      def invalid_jti
        msg = "Invalid jti for refresh token"
        render status: 401, json: { status: 401, error: msg }
      end

      # ログイン時に受け取るパラメータ(email, password)
      def auth_params
        params.require(:auth).permit(:email, :password)
      end
    end
  end
end
