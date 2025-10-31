# frozen_string_literal: true

class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false, comment: "タグ名（例: 外食、自炊）"
      t.timestamps
    end

    add_index :tags, :name, unique: true
  end
end
