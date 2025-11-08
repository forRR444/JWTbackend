# frozen_string_literal: true

require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Backend
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0
    # I18n設定(エラーメッセージの日本語化をデフォルトにする)
    config.i18n.default_locale = :ja
    config.i18n.available_locales = %i[en ja]

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Cookieを処理するmiddleware
    config.middleware.use ActionDispatch::Cookies

    # Cookieのsamesite属性を変更する(開発環境でnoneを使用するとCookieの共有ができない)
    if Rails.env.production?
      # 環境変数が未設定の場合はデフォルトで:laxを使用
      cookies_same_site = ENV.fetch("COOKIES_SAME_SITE", "lax").to_sym
      config.action_dispatch.cookies_same_site_protection = cookies_same_site
    end

    # Content Security Policy設定（XSS攻撃対策）
    allowed_origins = ENV.fetch("ALLOWED_ORIGINS", "http://localhost:5173").split(",").join(" ")
    csp_policy = [
      "default-src 'self'",
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'",
      "style-src 'self' 'unsafe-inline'",
      "img-src 'self' data: https:",
      "font-src 'self' data:",
      "connect-src 'self' #{allowed_origins};"
    ].join("; ")

    config.action_dispatch.default_headers.merge!(
      "Content-Security-Policy" => csp_policy
    )

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
