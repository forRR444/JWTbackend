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
    if token.blank? && request.headers["Authorization"].present?
      auth_header = request.headers["Authorization"]
      # "Bearer <token>" 形式から取得
      token = auth_header.start_with?("Bearer ") ? auth_header[7..] : auth_header
      Rails.logger.debug "[DEBUG] Token from Authorization header: #{token&.slice(0, 50)}"
    else
      Rails.logger.debug "[DEBUG] Token from cookies: #{token&.slice(0, 50)}"
    end

    token
  end

  # リフレッシュトークンからユーザーを取得（無効ならnil）
  def fetch_user_from_refresh_token
    token = token_from_cookies
    log_fetch_attempt
    user = User.from_refresh_token(token)
    log_fetch_success(user)
    user
  rescue JWT::InvalidJtiError => e
    handle_invalid_jti_error(e)
  rescue UserAuth.not_found_exception_class => e
    handle_not_found_error(e)
  rescue JWT::DecodeError, JWT::EncodeError => e
    handle_jwt_error(e)
  rescue StandardError => e
    handle_unexpected_error(e)
  end

  # トークン取得試行をログ出力
  def log_fetch_attempt
    Rails.logger.debug "[DEBUG] Attempting to fetch user from refresh token..."
  end

  # ユーザー取得成功をログ出力
  def log_fetch_success(user)
    Rails.logger.debug "[DEBUG] Successfully fetched user: #{user&.id}"
  end

  # Invalid JTI エラー処理
  def handle_invalid_jti_error(error)
    Rails.logger.error "[ERROR] Invalid JTI: #{error.message}"
    catch_invalid_jti
  end

  # ユーザー未検出エラー処理
  def handle_not_found_error(error)
    Rails.logger.error "[ERROR] User not found: #{error.message}"
    nil
  end

  # JWT関連エラー処理
  def handle_jwt_error(error)
    Rails.logger.error "[ERROR] JWT error: #{error.message}"
    nil
  end

  # 予期しないエラー処理
  def handle_unexpected_error(error)
    Rails.logger.error "[ERROR] Unexpected error: #{error.class} - #{error.message}"
    Rails.logger.error error.backtrace.first(5).join("\n")
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
