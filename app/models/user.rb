require "validator/email_validator"

class User < ApplicationRecord
  #Token生成モジュール
  include TokenGenerateService
  before_validation :downcase_email
  # gem bcrypt
  # 新規登録の時は、allow_nil: trueがあってもpasswordのバリデーションが働く
  has_secure_password
  has_many :meals, dependent: :destroy

  # validates
  validates :name, presence: true,
                   length: {
                     maximum: 30,
                     allow_blank: true # nil・空文字の時無駄な検証を行わない
                   }

  validates :email, presence: true,
                    email: { allow_blank: true }

  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
  validates :password, presence: true, # 空白・空文字列を許可しない
                       length: { minimum: 8,
                                 allow_blank: true },
                       format: { # 書式チェック
                         with: VALID_PASSWORD_REGEX,
                         message: :invalid_password, # ja.ymlで日本語エラーメッセージを定義
                         allow_blank: true
                       },
                       allow_nil: true # nilの時はバリデーションをスルー

                       ## methods
  # class method  ###########################
  class << self
    # emailからアクティブなユーザーを返す
    def find_by_activated(email)
      find_by(email: email, activated: true)
    end
  end
  # class method end #########################

  # 自分以外の同じemailのアクティブなユーザーがいる場合にtrueを返す
  def email_activated?
    users = User.where.not(id: id)
    users.find_by_activated(email).present?
  end

  # リフレッシュトークンのJWT IDを記憶する
  def remember(jti)
    update!(refresh_jti: jti)
  end

  # リフレッシュトークンのJWT IDを削除する
  def forget
    update!(refresh_jti: nil)
  end

  # 共通のJSONレスポンス
  def response_json(payload = {})
  as_json(only: [:id, :name]).merge(payload).with_indifferent_access
  end

  private

    # email小文字化
    def downcase_email
      self.email.downcase! if email
    end

end
