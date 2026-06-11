require "test_helper"

class SubtasksCompleteSubtaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Principal", column: @column)
    @subtask = Subtask.create!(title: "Passo 1", task: @task)
  end

  test "completes subtask" do
    result = Subtasks::CompleteSubtask.call(@subtask.id)

    assert result.success?
    assert_not_nil result.data.completed_at
  end

  test "toggles subtask completion" do
    Subtasks::CompleteSubtask.call(@subtask.id)
    assert_not_nil @subtask.reload.completed_at

    result = Subtasks::CompleteSubtask.call(@subtask.id)
    assert result.success?
    assert_nil result.data.completed_at
  end

  test "fails for non-existent subtask" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Subtasks::CompleteSubtask.call(-1)
    end
  end
end
