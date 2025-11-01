require 'roo'

namespace :food_data do
  desc "Import food composition data from Excel file"
  task import: :environment do
    file_path = Rails.root.join('20201225-mxt_kagsei-mext_01110_012.xlsx').to_s

    puts "Opening Excel file: #{file_path}"
    xlsx = Roo::Spreadsheet.open(file_path)

    # 「表全体」シートを使用
    sheet = xlsx.sheet(0)

    puts "Total rows: #{sheet.last_row}"
    puts "Starting import..."

    # データは13行目から開始
    # Row 11: 単位行
    # Row 12: 成分識別子行
    # Row 13以降: 実データ
    data_start_row = 13
    imported_count = 0
    skipped_count = 0
    error_count = 0

    Food.transaction do
      (data_start_row..sheet.last_row).each do |row_num|
        row_data = sheet.row(row_num)

        # 空行をスキップ
        next if row_data[1].nil? || row_data[1].to_s.strip.empty?

        # カラムインデックス (0-based)
        # Row 13の例: ["01", "01001", 1, "アマランサス　玄穀", 0, 1452, 343, 13.5, "(11.3)", 12.7, ...]
        # Col 0: 食品番号 (01)
        # Col 1: 索引番号 (01001)
        # Col 2: 連番 (1)
        # Col 3: 食品名 (アマランサス　玄穀)
        # Col 6: エネルギー kcal (343)
        # Col 7: 水分 (13.5)
        # Col 9: たんぱく質 (12.7)
        # Col 10: 脂質
        # Col 13: 炭水化物
        food_code = row_data[0]&.to_s&.strip
        index_number = row_data[1]&.to_s&.strip
        name = row_data[3]&.to_s&.strip

        # 必須フィールドチェック
        if food_code.blank? || index_number.blank? || name.blank?
          skipped_count += 1
          next
        end

        # 栄養素データを取得（括弧内の値や"-"、"Tr"などを除外）
        calories = parse_numeric_value(row_data[6])
        protein = parse_numeric_value(row_data[9])
        fat = parse_numeric_value(row_data[10])
        carbohydrate = parse_numeric_value(row_data[13])

        begin
          Food.create!(
            food_code: food_code,
            index_number: index_number,
            name: name,
            calories: calories,
            protein: protein,
            fat: fat,
            carbohydrate: carbohydrate
          )
          imported_count += 1

          # 進捗表示（100件ごと）
          if imported_count % 100 == 0
            puts "Imported #{imported_count} foods..."
          end
        rescue => e
          error_count += 1
          puts "Error importing row #{row_num}: #{e.message}"
          puts "Data: #{row_data.first(15).inspect}"
        end
      end
    end

    puts "\n=== Import completed ==="
    puts "Successfully imported: #{imported_count} foods"
    puts "Skipped: #{skipped_count} rows"
    puts "Errors: #{error_count} rows"
  end

  private

  def parse_numeric_value(value)
    return nil if value.nil?

    value_str = value.to_s.strip

    # 空文字、"-"、"Tr"（微量）は除外
    return nil if value_str.empty? || value_str == '-' || value_str.downcase == 'tr'

    # 括弧を除去（推定値も取り込む）
    # "(0.3)" -> "0.3"
    value_str = value_str.gsub(/[()]/, '')

    # 数値に変換
    begin
      Float(value_str)
    rescue ArgumentError
      nil
    end
  end
end
