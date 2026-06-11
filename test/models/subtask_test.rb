require "test_helper"

class SubtaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "Todo", position: 0)
    @task = Task.create!(title: "Tarefa principal", column: @column)
  end

  test "valid with title and task" do
    subtask = Subtask.new(title: "Passo 1", task: @task)
    assert subtask.valid?
  end

  test "invalid without title" do
    subtask = Subtask.new(task: @task)
    assert_not subtask.valid?
    assert_includes subtask.errors[:title], "can't be blank"
  end

  test "belongs to task" do
    subtask = Subtask.create!(title: "Passo 1", task: @task)
    assert_equal @task, subtask.task
  end

  test "completed scope returns completed subtasks" do
    completed = Subtask.create!(title: "Feito", task: @task, completed_at: Time.current)
    pending = Subtask.create!(title: "Pendente", task: @task)

    assert_includes Subtask.completed, completed
    assert_not_includes Subtask.completed, pending
  end

  test "pending scope returns non-completed subtasks" do
    completed = Subtask.create!(title: "Feito", task: @task, completed_at: Time.current)
    pending = Subtask.create!(title: "Pendente", task: @task)

    assert_includes Subtask.pending, pending
    assert_not_includes Subtask.pending, completed
  end

  test "ordered scope sorts by position" do
    s1 = Subtask.create!(title: "B", task: @task, position: 2)
    s2 = Subtask.create!(title: "A", task: @task, position: 0)
    s3 = Subtask.create!(title: "C", task: @task, position: 1)

    assert_equal [s2, s3, s1], Subtask.ordered.to_a
  end
end
