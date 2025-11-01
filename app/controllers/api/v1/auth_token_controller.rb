class Api::V1::AuthTokenController < ApplicationController
  include UserSessionizeService
  include TokenCookieHandler

  # 404エラーが発生した場合にヘッダーのみを返す
  rescue_from UserAuth.not_found_exception_class, with: :not_found
  # refresh_tokenのInvalidJitErrorが発生した場合はカスタムエラーを返す
  rescue_from JWT::InvalidJtiError, with: :invalid_jti

  # userのログイン情報を確認する
  before_action :authenticate, only: [ :create ]
  # 処理前にsessionを削除する
  before_action :delete_session, only: [ :create ]
  # session_userを取得、存在しない場合は401を返す
  before_action :sessionize_user, only: [ :refresh, :destroy ]

  # ログイン
  def create
    @user = login_user
    set_refresh_token_cookie(@user)
    render json: login_response
  end

  # リフレッシュ
  def refresh
    @user = session_user
    set_refresh_token_cookie(@user)
    render json: login_response
  end

  # ログアウト
  def destroy
    session_user.forget
    delete_refresh_token_cookie
    head :ok
  end

  private

  # params[:email]からアクティブなユーザーを返す
  def login_user
    @_login_user ||= User.find_by_activated(auth_params[:email])
  end

  # ログインユーザーが居ない、もしくはpasswordが一致しない場合404を返す
  def authenticate
    unless login_user.present? &&
            login_user.authenticate(auth_params[:password])
      raise UserAuth.not_found_exception_class
    end
  end

  # ログイン時のデフォルトレスポンス
  def login_response
    access = @user.encode_access_token
    {
      token: access.token,
      expires: access.payload[:exp],
      user: @user.response_json(sub: access.payload[:sub])
    }
  end

  # 404ヘッダーのみの返却を行う
  # Doc: https://gist.github.com/mlanett/a31c340b132ddefa9cca
  def not_found
    head(:not_found)
  end

  # decode jti != user.refresh_jti のエラー処理
  def invalid_jti
    msg = "Invalid jti for refresh token"
    render status: 401, json: { status: 401, error: msg }
  end

  def auth_params
    params.require(:auth).permit(:email, :password)
  end
end
