# frozen_string_literal: true

module UserAuth
  # access tokenの有効期限
  mattr_accessor :access_token_lifetime
  self.access_token_lifetime = ENV.fetch("ACCESS_TOKEN_LIFETIME", "1").to_i.minute

  # refresh tokenの有効期限
  mattr_accessor :refresh_token_lifetime
  self.refresh_token_lifetime = ENV.fetch("REFRESH_TOKEN_LIFETIME", "1440").to_i.minute

  # cookieからrefresh tokenを取得する際のキー
  # 環境ごとに異なるCookie名を使用（localhost間の干渉を防ぐ）
  mattr_accessor :session_key
  self.session_key = ENV.fetch("SESSION_COOKIE_NAME", "refresh_token").to_sym

  # userを識別するクレーム名
  mattr_accessor :user_claim
  self.user_claim = :sub

  # JWTの発行者を識別する文字列(認可サーバーURL)
  mattr_accessor :token_issuer
  self.token_issuer = ENV.fetch("BASE_URL", nil)

  # JWTの受信者を識別する文字列(保護リソースURL)
  mattr_accessor :token_audience
  self.token_audience = ENV.fetch("BASE_URL", nil)

  # JWTの署名アルゴリズム
  mattr_accessor :token_signature_algorithm
  self.token_signature_algorithm = "HS256"

  # 署名・検証に使用する秘密鍵
  mattr_accessor :token_secret_signature_key
  self.token_secret_signature_key = ENV['SECRET_KEY_BASE'] || Rails.application.credentials.secret_key_base

  # 署名・検証に使用する公開鍵(RS256)
  mattr_accessor :token_public_key
  self.token_public_key = nil

  # ユーザーが見つからない場合のエラー
  mattr_accessor :not_found_exception_class
  self.not_found_exception_class = ActiveRecord::RecordNotFound
end
