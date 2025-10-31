require "roo"

namespace :food_data do
  desc "Inspect the structure of the food composition Excel file"
  task inspect: :environment do
    file_path = Rails.root.join("20201225-mxt_kagsei-mext_01110_012.xlsx").to_s

    puts "Opening Excel file: #{file_path}"
    xlsx = Roo::Spreadsheet.open(file_path)

    puts "\n=== Available Sheets ==="
    xlsx.sheets.each_with_index do |sheet_name, index|
      puts "#{index + 1}. #{sheet_name}"
    end

    # 最初のシートを確認
    first_sheet = xlsx.sheet(0)
    puts "\n=== First Sheet: #{xlsx.sheets.first} ==="
    puts "Rows: #{first_sheet.last_row}"
    puts "Columns: #{first_sheet.last_column}"

    puts "\n=== First 10 rows of first sheet ==="
    (1...[ first_sheet.last_row, 10 ].min).each do |row_num|
      row_data = first_sheet.row(row_num)
      puts "Row #{row_num}: #{row_data.first(10).inspect}"
    end

    # ヘッダー行を探す（通常は「食品番号」などのキーワードがある行）
    puts "\n=== Looking for header row ==="
    (1..20).each do |row_num|
      row_data = first_sheet.row(row_num)
      if row_data.any? { |cell| cell.to_s.include?("食品番号") || cell.to_s.include?("エネルギー") }
        puts "Potential header at row #{row_num}: #{row_data.first(15).inspect}"
      end
    end

    # ヘッダー行の詳細確認（row 2とrow 3を結合）
    puts "\n=== Detailed Header (Row 2-3) ==="
    row2 = first_sheet.row(2)
    row3 = first_sheet.row(3)
    (0..20).each do |col|
      next if row2[col].nil? && row3[col].nil?
      puts "Col #{col}: [#{row2[col]}] [#{row3[col]}]"
    end

    # 実際のデータ行を確認（10行目以降）
    puts "\n=== Sample Data Rows (10-15) ==="
    (10..15).each do |row_num|
      row_data = first_sheet.row(row_num)
      puts "Row #{row_num}: #{row_data.first(10).inspect}"
    end
  end
end
