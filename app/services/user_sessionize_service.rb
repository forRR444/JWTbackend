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

  # Cookieまたはリフレッシュトークンを取得
  # Cookie優先、なければAuthorizationヘッダーから取得
  def token_from_cookies
    # Cookieから取得を試みる
    token = cookies[session_key]

    # CookieになければAuthorizationヘッダーから取得
    if token.blank? && request.headers['Authorization'].present?
      auth_header = request.headers['Authorization']
      # "Bearer <token>" 形式から取得
      token = auth_header.start_with?('Bearer ') ? auth_header[7..] : auth_header
      Rails.logger.debug "[DEBUG] Token from Authorization header: #{token&.slice(0, 50)}"
    else
      Rails.logger.debug "[DEBUG] Token from cookies: #{token&.slice(0, 50)}"
    end

    token
  end

  # リフレッシュトークンからユーザーを取得（無効ならnil）
  def fetch_user_from_refresh_token
    token = token_from_cookies
    Rails.logger.debug "[DEBUG] Attempting to fetch user from refresh token..."
    user = User.from_refresh_token(token)
    Rails.logger.debug "[DEBUG] Successfully fetched user: #{user&.id}"
    user
  rescue JWT::InvalidJtiError => e
    # jtiエラーの場合はcontrollerに処理を委任
    Rails.logger.error "[ERROR] Invalid JTI: #{e.message}"
    catch_invalid_jti
  rescue UserAuth.not_found_exception_class => e
    Rails.logger.error "[ERROR] User not found: #{e.message}"
    nil
  rescue JWT::DecodeError => e
    Rails.logger.error "[ERROR] JWT Decode error: #{e.message}"
    nil
  rescue JWT::EncodeError => e
    Rails.logger.error "[ERROR] JWT Encode error: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "[ERROR] Unexpected error in fetch_user_from_refresh_token: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
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
