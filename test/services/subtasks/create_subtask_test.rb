require "test_helper"

class SubtasksCreateSubtaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Tarefa principal", column: @column)
  end

  test "creates subtask under parent task" do
    result = Subtasks::CreateSubtask.call(@task.id, title: "Passo 1")

    assert result.success?
    assert_equal "Passo 1", result.data.title
    assert_equal @task, result.data.parent_task
    assert_equal @column, result.data.column
  end

  test "fails without title" do
    result = Subtasks::CreateSubtask.call(@task.id, title: nil)

    assert_not result.success?
  end

  test "fails for non-existent parent task" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Subtasks::CreateSubtask.call(-1, title: "Teste")
    end
  end

  test "increments position" do
    Subtasks::CreateSubtask.call(@task.id, title: "First")
    result = Subtasks::CreateSubtask.call(@task.id, title: "Second")

    assert_equal 2, result.data.position
  end
end
