require "validator/email_validator"

class User < ApplicationRecord
  # トークン生成機能（JWT関連）を追加
  include TokenGenerateService
  # バリデーション前にメールアドレスを小文字化
  before_validation :downcase_email
  # パスワード暗号化(gem bcrypt)
  # 新規登録の時は、allow_nil: trueがあってもpasswordのバリデーションが働く
  has_secure_password
  # ユーザーが削除されたら食事データも削除
  has_many :meals, dependent: :destroy
  # 栄養目標の履歴管理
  has_many :nutrition_goals, dependent: :destroy
  # ユーザーカスタム食品
  has_many :user_foods, dependent: :destroy

  ## バリデーション設定
  # 名前: 必須・30文字以内
  validates :name, presence: true,
                   length: {
                     maximum: 30,
                     allow_blank: true # nil・空文字の時無駄な検証を行わない
                   }

  # メールアドレス: 必須・メール形式・一意性
  validates :email, presence: true,
                    email: { allow_blank: true },
                    uniqueness: { case_sensitive: false }

  # パスワード：英数字・ハイフン・アンダースコアのみ、8文字以上
  VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
  validates :password, presence: true, # 空白・空文字列を許可しない
                       length: { minimum: 8,
                                 allow_blank: true },
                       format: { # 書式チェック
                         with: VALID_PASSWORD_REGEX,
                         message: :invalid_password, # ja.ymlで日本語エラーメッセージを定義
                         allow_blank: true
                       },
                       allow_nil: true # 更新時などでnilを許可

  # クラスメソッド
  class << self
    # emailからアクティブなユーザーを返す
    def find_by_activated(email)
      find_by(email: email, activated: true)
    end
  end

  # 自分以外で同じメールアドレスかつ有効なユーザーがいるか？
  def email_activated?
    users = User.where.not(id: id)
    users.find_by_activated(email).present?
  end

  # リフレッシュトークンのJTIを記録（ログイン時）
  def remember(jti)
    update!(refresh_jti: jti)
  end

  # リフレッシュトークンのJTIを削除（ログアウト時）
  def forget
    update!(refresh_jti: nil)
  end

  # 現在有効な栄養目標を取得
  def current_goal
    nutrition_goals.active.order(start_date: :desc).first
  end

  # レスポンス用JSON(id・名前・目標栄養素)を生成
  def response_json(payload = {})
    goal = current_goal
    base_json = as_json(only: [ :id, :name ])

    # 現在の目標値を追加
    if goal
      base_json.merge!(
        target_calories: goal.target_calories,
        target_protein: goal.target_protein,
        target_fat: goal.target_fat,
        target_carbohydrate: goal.target_carbohydrate
      )
    end

    base_json.merge(payload).with_indifferent_access
  end

  private
    # email小文字化
    def downcase_email
      self.email.downcase! if email
    end
end
