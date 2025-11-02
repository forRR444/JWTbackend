# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Cache assets for far-future expiry since they are all digest stamped.
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.asset_host = "http://assets.example.com"

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  # Docker環境ではSSLを無効化できるように環境変数で制御
  config.assume_ssl = ENV.fetch("RAILS_ASSUME_SSL", "true") == "true"

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Docker環境ではSSLを無効化できるように環境変数で制御
  config.force_ssl = ENV.fetch("RAILS_FORCE_SSL", "true") == "true"

  # Skip http-to-https redirect for the default health check endpoint.
  # config.ssl_options = { redirect: { exclude: ->(request) { request.path == "/up" } } }

  # Log to STDOUT with the current request id as a default log tag.
  config.log_tags = [:request_id]
  config.logger   = ActiveSupport::TaggedLogging.logger($stdout)

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Replace the default in-process memory cache store with a durable alternative.
  # Docker環境では複雑な設定を避けるため、シンプルなmemory_storeを使用
  config.cache_store = :memory_store
  # config.cache_store = :solid_cache_store

  # Replace the default in-process and non-durable queuing backend for Active Job.
  # Docker環境では複雑な設定を避けるため、シンプルなasyncアダプタを使用
  # 本番環境でSolid Queueを使う場合は、複数データベース設定が必要
  config.active_job.queue_adapter = :async
  # config.active_job.queue_adapter = :solid_queue
  # config.solid_queue.connects_to = { database: { writing: :queue } }

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  # config.action_mailer.raise_delivery_errors = false

  # Set host to be used by links generated in mailer templates.
  config.action_mailer.default_url_options = { host: "example.com" }

  # Specify outgoing SMTP server. Remember to add smtp/* credentials via rails credentials:edit.
  # config.action_mailer.smtp_settings = {
  #   user_name: Rails.application.credentials.dig(:smtp, :user_name),
  #   password: Rails.application.credentials.dig(:smtp, :password),
  #   address: "smtp.example.com",
  #   port: 587,
  #   authentication: :plain
  # }

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Only use :id for inspections in production.
  config.active_record.attributes_for_inspect = [:id]

  # Enable DNS rebinding protection and other `Host` header attacks.
  # 環境変数 APP_HOST で許可するホストを指定
  # 環境変数 APP_DOMAIN でサブドメインのワイルドカードパターンを指定
  # Docker環境では DISABLE_HOST_CHECK=true で無効化可能
  if ENV["DISABLE_HOST_CHECK"] == "true"
    config.hosts.clear
  elsif ENV["APP_HOST"].present?
    allowed_hosts = [ENV["APP_HOST"]]

    # APP_DOMAIN が設定されている場合、サブドメインも許可
    allowed_hosts << /.*\.#{Regexp.escape(ENV['APP_DOMAIN'])}/ if ENV["APP_DOMAIN"].present?

    config.hosts = allowed_hosts

    # ヘルスチェックエンドポイントは認証をスキップ
    config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
  else
    # デフォルトではHeroku、Renderのドメインとlocalhostを許可
    config.hosts = [
      "localhost",
      /localhost:\d+/,
      "127.0.0.1",
      /127\.0\.0\.1:\d+/,
      /.*\.herokuapp\.com/,  # Herokuのすべてのドメインを許可
      /.*\.onrender\.com/    # Renderのすべてのドメインを許可
    ]
  end
end
