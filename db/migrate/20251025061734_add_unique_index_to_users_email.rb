# frozen_string_literal: true

class AddUniqueIndexToUsersEmail < ActiveRecord::Migration[8.0]
  def change
    # メールアドレスの一意性をDB制約レベルで保証
    add_index :users, :email, unique: true
  end
end
