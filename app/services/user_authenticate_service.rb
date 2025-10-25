module UserAuthenticateService
  # 認証（ログイン中ユーザーがいるか確認）
  def authenticate_user
    current_user.present? || unauthorized_user
  end

  # 認証 + 有効ユーザー確認（メール認証済みなど）
  # 現在はメール認証は未実装のため、activated?は常にtrueを返す
  def authenticate_active_user
    (current_user.present? && current_user.activated?) || unauthorized_user
  end

  private
    # リクエストヘッダーからトークンを取得
    def token_from_request_headers
      request.headers["Authorization"]&.split&.last
    end

    # トークンからユーザーを取得（無効ならnil）
    def fetch_user_from_access_token
      User.from_access_token(token_from_request_headers)
    # 見つからない場合nilを返す
    rescue UserAuth.not_found_exception_class,
           JWT::DecodeError, JWT::EncodeError
      nil
    end

    # アクセストークンのユーザーを返す
    def current_user
      return nil unless token_from_request_headers
      @_current_user ||= fetch_user_from_access_token
    end

    # 認証失敗時の処理（Cookie削除 + 401返却）
    def unauthorized_user
      cookies.delete(UserAuth.session_key)
      head(:unauthorized)
    end
end
