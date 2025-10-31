# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = active_user
  end

  # 名前のバリデーションを検証
  test "name_validation" do
    # 入力必須
    user = User.new(email: "test@example.com", password: "password")
    user.save
    required_msg = ["名前を入力してください"]
    assert_equal(required_msg, user.errors.full_messages)

    # 文字数30字まで
    max = 30
    name = "a" * (max + 1)
    user.name = name
    user.save
    length_msg = ["名前は30文字以内で入力してください"]
    assert_equal(length_msg, user.errors.full_messages)

    # 30字以下で登録成功
    name = "あ" * max
    user.name = name
    assert_difference("User.count", 1) do
      user.save
    end
  end

  # メールアドレスのバリデーションを検証
  test "email_validation" do
    # 入力必須
    user = User.new(name: "test", password: "password")
    user.save
    required_msg = ["メールアドレスを入力してください"]
    assert_equal(required_msg, user.errors.full_messages)

    # 文字数255字まで
    max = 255
    domain = "@example.com"
    email = ("a" * (max - domain.length + 1)) + domain
    assert max < email.length
    user.email = email
    user.save
    maxlength_msg = ["メールアドレスは255文字以内で入力してください"]
    assert_equal(maxlength_msg, user.errors.full_messages)

    # 正しい書式は保存できているか
    ok_emails = %w[
      A@EX.COM
      a-_@e-x.c-o_m.j_p
      a.a@ex.com
      a@e.co.js
      1.1@ex.com
      a.a+a@ex.com
    ]
    ok_emails.each do |email|
      user.email = email
      assert user.save
    end

    # 間違った書式は保存できないか
    ng_emails = %w[
      aaa
      a.ex.com
      メール@ex.com
      a~a@ex.com
      a@|.com
      a@ex.
      .a@ex.com
      a＠ex.com
      Ａ@ex.com
      a@?,com
      １@ex.com
      "a"@ex.com
      a@ex@co.jp
    ]
    ng_emails.each do |email|
      user.email = email
      user.save
      format_msg = ["メールアドレスは不正な値です"]
      assert_equal(format_msg, user.errors.full_messages)
    end
  end

  # メールアドレスが小文字化されることを検証
  test "email_downcase" do
    # emailが小文字化されているか
    email = "USER@EXAMPLE.COM"
    user = User.new(email: email)
    user.save
    assert user.email == email.downcase
  end

  # メールアドレスの一意性を検証
  test "email_uniqueness" do
    # メールアドレスは常に一意（activated に関わらず）
    email = "test@example.com"

    # 最初のユーザーは作成できる
    assert_difference("User.count", 1) do
      User.create(name: "test1", email: email, password: "password")
    end

    # 同じメールアドレスで2人目は作成できない（activated に関わらず）
    assert_no_difference("User.count") do
      user = User.new(name: "test2", email: email, password: "password")
      user.save
      uniqueness_msg = ["メールアドレスはすでに存在します"]
      assert_equal(uniqueness_msg, user.errors.full_messages)
    end

    # activated: true でも同じメールアドレスは作成できない
    first_user = User.find_by(email: email)
    first_user.update!(activated: true)

    assert_no_difference("User.count") do
      user = User.new(name: "test3", email: email, password: "password", activated: true)
      user.save
      uniqueness_msg = ["メールアドレスはすでに存在します"]
      assert_equal(uniqueness_msg, user.errors.full_messages)
    end

    # ユーザーを削除すると、同じメールアドレスで作成可能になる
    first_user.destroy!
    assert_difference("User.count", 1) do
      User.create(name: "test4", email: email, password: "password", activated: true)
    end

    # メールアドレスの一意性は保たれているか
    assert_equal(1, User.where(email: email).count)
  end

  # パスワードのバリデーションを検証
  test "password_validation" do
    # 入力必須
    user = User.new(name: "test", email: "test@example.com")
    user.save
    required_msg = ["パスワードを入力してください"]
    assert_equal(required_msg, user.errors.full_messages)

    # min文字以上
    min = 8
    user.password = "a" * (min - 1)
    user.save
    minlength_msg = ["パスワードは8文字以上で入力してください"]
    assert_equal(minlength_msg, user.errors.full_messages)

    # max文字以下
    max = 72
    user.password = "a" * (max + 1)
    user.save
    maxlength_msg = ["パスワードが長すぎます"]
    assert_equal(maxlength_msg, user.errors.full_messages)

    # 書式チェック VALID_PASSWORD_REGEX = /\A[\w\-]+\z/
    ok_passwords = %w[
      pass---word
      ________
      12341234
      ____pass
      pass----
      PASSWORD
    ]
    ok_passwords.each do |pass|
      user.password = pass
      assert user.save
    end

    ng_passwords = %w[
      pass/word
      pass.word
      |~=?+"a"
      １２３４５６７８
      ＡＢＣＤＥＦＧＨ
      password@
    ]
    format_msg = ["パスワードは半角英数字•ﾊｲﾌﾝ•ｱﾝﾀﾞｰﾊﾞｰが使えます"]
    ng_passwords.each do |pass|
      user.password = pass
      user.save
      assert_equal(format_msg, user.errors.full_messages)
    end
  end
end
