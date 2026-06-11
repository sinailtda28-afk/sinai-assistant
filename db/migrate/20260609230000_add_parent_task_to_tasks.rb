class AddParentTaskToTasks < ActiveRecord::Migration[8.1]
  def change
    add_reference :tasks, :parent_task, foreign_key: { to_table: :tasks }, null: true
    add_column :tasks, :is_recurring, :boolean, default: false
    add_column :tasks, :recurring_interval, :string
    add_column :tasks, :completed_count, :integer, default: 0
  end
end
