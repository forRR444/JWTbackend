# 食品成分表データのセットアップ

## 概要

このアプリケーションは、文部科学省「日本食品標準成分表2020年版（八訂）」のデータを使用しています。
データベースに約2,500件の食品情報（カロリー、たんぱく質、脂質、炭水化物）が格納されます。

**重要**: SQLダンプファイル(`db/foods_data.sql`)がGitリポジトリに含まれているため、Excelファイルは不要です。

## セットアップ手順（開発・本番共通）

### 1. データベースのマイグレーション

```bash
bin/rails db:migrate

# 本番環境の場合
RAILS_ENV=production bin/rails db:migrate
```

### 2. 食品データのインポート（SQLダンプから）

```bash
bundle exec rake db:seed:foods

# 本番環境の場合
RAILS_ENV=production bundle exec rake db:seed:foods
```

このコマンドで約2,478件の食品データがインポートされます（所要時間: 約10-20秒）

### 3. データの確認

```bash
bin/rails runner "puts \"Total foods: #{Food.count}\""

# 本番環境の場合
RAILS_ENV=production bin/rails runner "puts \"Total foods: #{Food.count}\""
```

## ファイル構成

```
JWTbackend/
├── db/
│   ├── foods_data.sql          # SQLダンプファイル (716KB)
│   └── migrate/
│       └── 20251022062326_create_foods.rb
└── lib/tasks/
    ├── foods_import.rake       # SQLインポート用Rakeタスク
    └── import_food_data.rake   # Excel読み込み用（開発時のみ）
```

## 開発時にExcelから再エクスポートする場合

食品成分表が更新された場合のみ、以下の手順で再エクスポートします:

### 1. Excelファイルの配置

- ファイル名: `20201225-mxt_kagsei-mext_01110_012.xlsx`
- ダウンロード元: [文部科学省 食品成分データベース](https://www.mext.go.jp/a_menu/syokuhinseibun/mext_01110.html)
- 配置場所: `JWTbackend/` (プロジェクトルート)

### 2. Excelからインポート

```bash
bundle exec rake food_data:import
```

### 3. SQLダンプの再作成

```bash
pg_dump -h localhost -d backend_development \
  --table=foods --data-only --column-inserts \
  --no-owner --no-privileges \
  -f db/foods_data.sql
```

### 4. Excelファイルの削除

```bash
rm 20201225-mxt_kagsei-mext_01110_012.xlsx
```

## データの更新

食品成分表が更新された場合:

1. 新しいExcelファイルを取得
2. 既存データを削除
   ```bash
   bin/rails runner "Food.delete_all"
   ```
3. 再インポート
   ```bash
   bundle exec rake food_data:import
   ```

## トラブルシューティング

### インポートエラーが発生する場合

1. Excelファイルのパスを確認
2. 必要なgemがインストールされているか確認
   ```bash
   bundle install
   ```
3. データベース接続を確認

### 検索結果が空の場合

1. データがインポートされているか確認
   ```bash
   bin/rails runner "puts Food.count"
   ```
2. 食品名で検索してみる
   ```bash
   bin/rails runner "puts Food.where('name LIKE ?', '%卵%').first&.name"
   ```

## ファイル管理

- **Excelファイル (1.9MB)** は `.gitignore` に追加済み
- Gitリポジトリには含まれません
- 本番環境では初回セットアップ後に削除可能
- データはデータベースに永続化されます

## データベーススキーマ

```ruby
create_table :foods do |t|
  t.string :food_code          # 食品番号 (例: "01")
  t.string :index_number       # 索引番号 (例: "01001")
  t.string :name               # 食品名
  t.decimal :calories          # エネルギー (kcal/100g)
  t.decimal :protein           # たんぱく質 (g/100g)
  t.decimal :fat               # 脂質 (g/100g)
  t.decimal :carbohydrate      # 炭水化物 (g/100g)
  t.timestamps
end

add_index :foods, :name
add_index :foods, :index_number, unique: true
```

## API使用例

```bash
# 食品検索
curl -X GET "http://localhost:3000/api/v1/foods?q=卵" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "X-Requested-With: XMLHttpRequest"
```

## 注意事項

1. 食品成分表データの著作権は文部科学省に帰属します
2. 商用利用の場合は文部科学省のガイドラインを確認してください
3. データは100gあたりの値です
