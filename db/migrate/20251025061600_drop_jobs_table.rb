class DropJobsTable < ActiveRecord::Migration[8.0]
  def change
    drop_table :jobs do |t|
      t.string :title
      t.string :category
      t.integer :salary
      t.timestamps
    end
  end
end
