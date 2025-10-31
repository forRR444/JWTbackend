# frozen_string_literal: true

module UserSessionizeService
  # セッションユーザーが存在すればOK、いなければ401を返す
  def sessionize_user
    session_user.present? || unauthorized_user
  end

  # セッションキー名を取得
  def session_key
    UserAuth.session_key
  end

  # セッションcookieを削除
  def delete_session
    cookies.delete(session_key)
  end

  private

  # Cookieからリフレッシュトークンを取得
  def token_from_cookies
    cookies[session_key]
  end

  # リフレッシュトークンからユーザーを取得（無効ならnil）
  def fetch_user_from_refresh_token
    User.from_refresh_token(token_from_cookies)
  rescue JWT::InvalidJtiError
    # jtiエラーの場合はcontrollerに処理を委任
    catch_invalid_jti
  rescue UserAuth.not_found_exception_class,
         JWT::DecodeError, JWT::EncodeError
    nil
  end

  # セッション中のユーザーを返す
  def session_user
    return nil unless token_from_cookies

    @session_user ||= fetch_user_from_refresh_token
  end

  # jtiエラーの処理（セッション削除＋例外発生）
  def catch_invalid_jti
    delete_session
    raise JWT::InvalidJtiError
  end

  # 認証失敗時の処理（Cookie削除＋401返却）
  def unauthorized_user
    delete_session
    head(:unauthorized)
  end
end
