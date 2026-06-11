require "test_helper"

class TaskTagTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "Todo", position: 0)
    @task = Task.create!(title: "Tarefa", column: @column)
    @tag = Tag.create!(name: "projeto")
  end

  test "valid with task and tag" do
    tt = TaskTag.new(task: @task, tag: @tag)
    assert tt.valid?
  end

  test "belongs to task" do
    tt = TaskTag.create!(task: @task, tag: @tag)
    assert_equal @task, tt.task
  end

  test "belongs to tag" do
    tt = TaskTag.create!(task: @task, tag: @tag)
    assert_equal @tag, tt.tag
  end

  test "task_id and tag_id combo must be unique" do
    TaskTag.create!(task: @task, tag: @tag)
    duplicate = TaskTag.new(task: @task, tag: @tag)
    assert_not duplicate.valid?
  end
end
