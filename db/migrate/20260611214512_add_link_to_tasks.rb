class AddLinkToTasks < ActiveRecord::Migration[8.1]
  def change
    add_column :tasks, :link, :string
  end
end
