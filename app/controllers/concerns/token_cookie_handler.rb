# Cookie経由でのリフレッシュトークン処理を提供
# UsersControllerとAuthTokenControllerで共通利用
module TokenCookieHandler
  extend ActiveSupport::Concern

  private

  # リフレッシュトークンをHttpOnly Cookieに設定
  # @param user [User] トークンを発行するユーザー
  def set_refresh_token_cookie(user)
    refresh = user.encode_refresh_token
    user.remember(refresh.payload[:jti])

    cookies[UserAuth.session_key] = {
      value: refresh.token,
      expires: Time.at(refresh.payload[:exp]),
      http_only: true,
      secure: Rails.env.production?,
      same_site: :lax
    }
  end

  # リフレッシュトークンCookieを削除
  def delete_refresh_token_cookie
    cookies.delete(UserAuth.session_key)
  end
end
