class CreateTaskTags < ActiveRecord::Migration[8.1]
  def change
    create_table :task_tags do |t|
      t.integer :task_id, null: false
      t.integer :tag_id, null: false

      t.timestamps
    end

    add_index :task_tags, [:task_id, :tag_id], unique: true
    add_foreign_key :task_tags, :tasks, column: :task_id
    add_foreign_key :task_tags, :tags, column: :tag_id
  end
end
