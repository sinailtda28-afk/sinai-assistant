require "test_helper"

class TasksRecurringTaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Diaria", column: @column, due_date: Date.current)
  end

  test "creates next daily task" do
    @task.update!(recurrence_type: "daily")
    result = Tasks::RecurringTask.call(@task)

    assert result.success?
    assert_equal "Diaria", result.data.title
    assert_equal (Date.current + 1.day).to_date, result.data.due_date.to_date
  end

  test "creates next weekly task" do
    @task.update!(recurrence_type: "weekly")
    result = Tasks::RecurringTask.call(@task)

    assert result.success?
    assert_equal (Date.current + 7.days).to_date, result.data.due_date.to_date
  end

  test "creates next monthly task" do
    @task.update!(recurrence_type: "monthly")
    result = Tasks::RecurringTask.call(@task)

    assert result.success?
    assert_equal (Date.current + 1.month).to_date, result.data.due_date.to_date
  end

  test "weekly with specific recurrence_day" do
    # Tuesday
    tuesday = Date.current.next_occurring(:tuesday)
    @task.update!(recurrence_type: "weekly", recurrence_day: 2)
    result = Tasks::RecurringTask.call(@task)

    assert result.success?
    assert_equal 2, result.data.due_date.wday
  end

  test "copies tags to new task" do
    tag = Tag.create!(name: "importante")
    @task.tags << tag
    @task.update!(recurrence_type: "daily")

    result = Tasks::RecurringTask.call(@task)
    assert_includes result.data.tags, tag
  end

  test "uses parent_task_id if present" do
    @task.update!(recurrence_type: "daily", parent_task_id: nil)
    result = Tasks::RecurringTask.call(@task)

    assert_equal @task.id, result.data.parent_task_id
  end

  test "places task in first column" do
    Column.create!(name: "Em Andamento", position: 1)
    @task.update!(recurrence_type: "daily")
    result = Tasks::RecurringTask.call(@task)

    assert_equal @column, result.data.column
  end

  test "increments position" do
    @task.update!(recurrence_type: "daily")
    result = Tasks::RecurringTask.call(@task)

    assert_equal 1, result.data.position
  end
end
