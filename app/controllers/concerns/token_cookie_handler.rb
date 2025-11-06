# frozen_string_literal: true

# Cookie経由でのリフレッシュトークン処理
module TokenCookieHandler
  extend ActiveSupport::Concern

  private

  # リフレッシュトークンをHttpOnly Cookieに設定
  def set_refresh_token_cookie(user)
    refresh = user.encode_refresh_token # トークン生成（JTIはRefreshToken#initializeで保存済み）
    set_refresh_token_cookie_from_token(refresh)
  end

  # 既に生成されたリフレッシュトークンをCookieに設定
  def set_refresh_token_cookie_from_token(refresh)
    # same_site設定: 環境変数で制御（デフォルトは:lax）
    # COOKIES_SAME_SITEが設定されている場合はその値を使用
    same_site_value = if ENV["COOKIES_SAME_SITE"].present?
                        ENV["COOKIES_SAME_SITE"].to_sym
                      else
                        :lax
                      end

    # secure設定: same_site: :noneの場合はsecure: trueが必須
    # それ以外はRAILS_FORCE_SSLまたは本番環境かどうかで判定
    use_secure_cookies = if same_site_value == :none
                           # same_site: :noneの場合は常にsecure: true（ブラウザ要件）
                           true
                         elsif ENV["RAILS_FORCE_SSL"].present?
                           ENV["RAILS_FORCE_SSL"] == "true"
                         else
                           Rails.env.production?
                         end

    cookies[UserAuth.session_key] = {
      value: refresh.token, # Cookieにトークン本体を保存
      expires: Time.at(refresh.payload[:exp]), # 有効期限設定
      http_only: true, # JavaScriptからのアクセス不可
      secure: use_secure_cookies, # HTTPS通信時のみ送信（Docker環境では無効化可能）
      same_site: same_site_value # CSRF対策（開発環境では:none）
    }
  end

  # リフレッシュトークンCookieを削除(ログアウト時など)
  def delete_refresh_token_cookie
    cookies.delete(UserAuth.session_key)
  end
end
