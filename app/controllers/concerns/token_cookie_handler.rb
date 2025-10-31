# frozen_string_literal: true

# Cookie経由でのリフレッシュトークン処理
module TokenCookieHandler
  extend ActiveSupport::Concern

  private

  # リフレッシュトークンをHttpOnly Cookieに設定
  def set_refresh_token_cookie(user)
    refresh = user.encode_refresh_token # トークン生成
    user.remember(refresh.payload[:jti]) # jtiをDB保存

    cookies[UserAuth.session_key] = {
      value: refresh.token, # Cookieにトークン本体を保存
      expires: Time.at(refresh.payload[:exp]), # 有効期限設定
      http_only: true, # JavaScriptからのアクセス不可
      secure: Rails.env.production?, # 本番環境のみHTTPS通信時に送信
      same_site: :lax # CSRF対策
    }
  end

  # リフレッシュトークンCookieを削除(ログアウト時など)
  def delete_refresh_token_cookie
    cookies.delete(UserAuth.session_key)
  end
end
