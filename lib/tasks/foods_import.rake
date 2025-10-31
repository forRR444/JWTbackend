namespace :db do
  namespace :seed do
    desc "Import food composition data from SQL dump (for production setup)"
    task foods: :environment do
      sql_file = Rails.root.join("db", "foods_data.sql")

      unless File.exist?(sql_file)
        puts "ERROR: SQL dump file not found at #{sql_file}"
        puts "Please ensure db/foods_data.sql exists in the project."
        exit 1
      end

      if Food.count > 0
        puts "Foods table already has #{Food.count} records."
        puts "Skipping import. (Run 'Food.delete_all' first if you want to re-import)"
        exit 0
      end

      puts "Importing food data from SQL dump..."
      puts "File: #{sql_file}"
      puts "Size: #{File.size(sql_file) / 1024}KB"

      # PostgreSQLのpsqlコマンドを使用してインポート
      db_config = ActiveRecord::Base.connection_db_config.configuration_hash

      command = [
        "psql",
        "-h", db_config[:host] || "localhost",
        "-U", db_config[:username] || ENV["USER"],
        "-d", db_config[:database],
        "-f", sql_file.to_s,
        "-q" # Quiet mode
      ]

      # パスワードが必要な場合は環境変数で設定
      env = {}
      env["PGPASSWORD"] = db_config[:password] if db_config[:password]

      puts "\nExecuting: #{command.join(' ')}"
      puts "(This may take 10-20 seconds...)\n"

      success = system(env, *command)

      if success
        count = Food.count
        puts "\n✓ Successfully imported #{count} food items!"
        puts "\nYou can now search foods via API:"
        puts "  GET /api/v1/foods?q=卵"
      else
        puts "\n✗ Import failed. Please check the error messages above."
        exit 1
      end
    end
  end
end

namespace :food_data do
  desc "Import food data from SQL dump (alias for db:seed:foods)"
  task import_sql: "db:seed:foods"
end
