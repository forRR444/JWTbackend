class CreateUserFoods < ActiveRecord::Migration[8.0]
  def change
    create_table :user_foods do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, comment: "食品名（例: マクドナルドのビッグマック）"
      t.decimal :calories, precision: 8, scale: 1, comment: "エネルギー (kcal/100g)"
      t.decimal :protein, precision: 8, scale: 1, comment: "たんぱく質 (g/100g)"
      t.decimal :fat, precision: 8, scale: 1, comment: "脂質 (g/100g)"
      t.decimal :carbohydrate, precision: 8, scale: 1, comment: "炭水化物 (g/100g)"
      t.integer :default_grams, comment: "デフォルトのグラム数"
      t.timestamps
    end

    add_index :user_foods, [ :user_id, :name ]
  end
end
