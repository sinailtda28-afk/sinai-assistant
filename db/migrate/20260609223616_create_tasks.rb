class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.integer :column_id, null: false
      t.string :title, null: false
      t.text :description
      t.datetime :due_date
      t.integer :priority, default: 1
      t.integer :position, default: 0
      t.datetime :completed_at

      t.timestamps
    end

    add_index :tasks, :column_id
    add_index :tasks, :due_date
    add_index :tasks, :priority
    add_index :tasks, :completed_at
    add_foreign_key :tasks, :columns, column: :column_id
  end
end
