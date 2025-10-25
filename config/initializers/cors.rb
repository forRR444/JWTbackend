Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:5173'
    resource '/api/*',
      headers: :any,# 全てのリクエストヘッダーを許可
      expose: ['Authorization'], # レスポンスヘッダーにAuthorizationを含める
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true # Cookieを許可
  end
end
