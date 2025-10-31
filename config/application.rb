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
      config.action_dispatch.cookies_same_site_protection =
        ENV["COOKIES_SAME_SITE"].to_sym
    end

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
