require "test_helper"

class TaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Revisar relatorio", column: @column, priority: :high)
  end

  test "valid with title and column" do
    task = Task.new(title: "Teste", column: @column)
    assert task.valid?
  end

  test "invalid without title" do
    task = Task.new(column: @column)
    assert_not task.valid?
    assert_includes task.errors[:title], "can't be blank"
  end

  test "belongs to column" do
    assert_equal @column, @task.column
  end

  test "can have parent task with subtasks" do
    subtask = Task.create!(title: "Subtarefa 1", column: @column, parent_task: @task)
    assert_includes @task.subtasks, subtask
    assert_equal @task, subtask.parent_task
  end

  test "can have tags through task_tags" do
    tag = Tag.create!(name: "importante")
    @task.tags << tag
    assert_includes @task.tags.reload, tag
  end

  test "priority enum values" do
    assert_equal "low", Task.new(priority: 0).priority
    assert_equal "medium", Task.new(priority: 1).priority
    assert_equal "high", Task.new(priority: 2).priority
  end

  test "completed scope returns only completed tasks" do
    @task.update!(completed_at: Time.current)
    pending_task = Task.create!(title: "Pendente", column: @column)

    assert_includes Task.completed, @task
    assert_not_includes Task.completed, pending_task
  end

  test "pending scope returns only non-completed tasks" do
    @task.update!(completed_at: Time.current)
    pending_task = Task.create!(title: "Pendente", column: @column)

    assert_includes Task.pending, pending_task
    assert_not_includes Task.pending, @task
  end

  test "parent_tasks scope returns tasks without parent" do
    subtask = Task.create!(title: "Sub", column: @column, parent_task: @task)
    assert_includes Task.parent_tasks, @task
    assert_not_includes Task.parent_tasks, subtask
  end

  test "subtasks scope returns tasks with parent" do
    subtask = Task.create!(title: "Sub", column: @column, parent_task: @task)
    assert_includes Task.subtasks, subtask
    assert_not_includes Task.subtasks, @task
  end

  test "recurring scope returns recurring tasks" do
    recurring = Task.create!(title: "Recorrente", column: @column, is_recurring: true)
    assert_includes Task.recurring, recurring
    assert_not_includes Task.recurring, @task
  end

  test "due_today scope returns tasks due today" do
    today_task = Task.create!(title: "Hoje", column: @column, due_date: Time.current)
    tomorrow_task = Task.create!(title: "Amanha", column: @column, due_date: 1.day.from_now)

    assert_includes Task.due_today, today_task
    assert_not_includes Task.due_today, tomorrow_task
  end

  test "overdue scope returns pending tasks past due" do
    overdue = Task.create!(title: "Atrasada", column: @column, due_date: 1.day.ago)
    future = Task.create!(title: "Futura", column: @column, due_date: 1.day.from_now)

    assert_includes Task.overdue, overdue
    assert_not_includes Task.overdue, future
  end

  test "by_priority_filter filters by priority" do
    low_task = Task.create!(title: "Baixa", column: @column, priority: :low)
    assert_includes Task.by_priority_filter("low"), low_task
    assert_not_includes Task.by_priority_filter("low"), @task
  end

  test "by_tag filters by tag name" do
    tag = Tag.create!(name: "financas")
    tagged = Task.create!(title: "Financeiro", column: @column)
    tagged.tags << tag

    assert_includes Task.by_tag("financas"), tagged
    assert_not_includes Task.by_tag("financas"), @task
  end

  test "due_in_range filters by date range" do
    t1 = Task.create!(title: "Dia 15", column: @column, due_date: Date.parse("2026-06-15"))
    t2 = Task.create!(title: "Dia 20", column: @column, due_date: Date.parse("2026-06-20"))
    t3 = Task.create!(title: "Dia 25", column: @column, due_date: Date.parse("2026-06-25"))

    result = Task.due_in_range("2026-06-14", "2026-06-21")
    assert_includes result, t1
    assert_includes result, t2
    assert_not_includes result, t3
  end

  test "by_priority ordering" do
    low = Task.create!(title: "Low", column: @column, priority: :low)
    medium = Task.create!(title: "Med", column: @column, priority: :medium)
    high = Task.create!(title: "High", column: @column, priority: :high)

    ordered = Task.by_priority
    assert_equal high, ordered.first
  end
end
