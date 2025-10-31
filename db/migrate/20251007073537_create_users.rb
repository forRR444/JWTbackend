# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :name, null: false # 空白・空文字列を許可しない
      t.string :email, null: false
      t.string :password_digest, null: false
      t.boolean :activated, null: false, default: false # デフォルトはfalse
      t.boolean :admin, null: false, default: false

      t.timestamps
    end
  end
end
