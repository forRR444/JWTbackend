class ApplicationController < ActionController::API
  #cookieを扱う
  include ActionController::Cookies
  # 認証を行う
  include UserAuthenticateService 
  # CSRF対策
  before_action :xhr_request?

  private

    # XMLHttpRequestでない場合は403エラーを返す
    def xhr_request?
      # リクエストヘッダ X-Requested-With: 'XMLHttpRequest' の存在を判定
      return if request.xhr?
      render status: :forbidden, json: { status: 403, error: "Forbidden" }
    end

    # Internal Server Error
    def response_500(msg = "Internal Server Error")
      render status: 500, json: { status: 500, error: msg }
    end

    # Not Found
    def not_found
      render status: 404, json: { status: 404, error: "Not Found" }
    end



end
