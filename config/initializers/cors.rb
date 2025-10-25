# CORS設定
# 環境変数 ALLOWED_ORIGINS でオリジンを指定（カンマ区切りで複数指定可能）
# 例: ALLOWED_ORIGINS=https://example.com,https://app.example.com
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # 環境変数から許可オリジンを取得（未設定時はlocalhost:5173をデフォルト）
    allowed_origins = ENV.fetch('ALLOWED_ORIGINS', 'http://localhost:5173').split(',').map(&:strip)
    origins allowed_origins

    resource '/api/*',
      headers: %w[Content-Type Authorization X-Requested-With], # 必要なヘッダーのみ許可
      expose: [ 'Authorization' ], # レスポンスヘッダーにAuthorizationを含める
      methods: [ :get, :post, :put, :patch, :delete, :options, :head ],
      credentials: true # Cookieを許可
  end
end
