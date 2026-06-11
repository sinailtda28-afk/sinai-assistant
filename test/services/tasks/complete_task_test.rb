require "test_helper"

class TasksCompleteTaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Tarefa", column: @column, due_date: 2.days.from_now)
  end

  test "completes task setting completed_at" do
    result = Tasks::CompleteTask.call(@task.id)

    assert result.success?
    assert_not_nil result.data.completed_at
  end

  test "increments completed_count" do
    result = Tasks::CompleteTask.call(@task.id)

    assert_equal 1, result.data.completed_count
  end

  test "increments completed_count for repeated completion" do
    Tasks::CompleteTask.call(@task.id)
    @task.reload.update!(completed_at: nil)
    result = Tasks::CompleteTask.call(@task.id)

    assert_equal 2, result.data.completed_count
  end

  test "recreates daily recurring task" do
    @task.update!(is_recurring: true, recurring_interval: "daily")
    result = Tasks::CompleteTask.call(@task.id)

    assert result.success?
    new_task = Task.where.not(id: @task.id).last
    assert_equal @task.title, new_task.title
    assert_in_delta (@task.due_date + 1.day).to_i, new_task.due_date.to_i, 1
  end

  test "recreates weekly recurring task" do
    @task.update!(is_recurring: true, recurring_interval: "weekly")
    result = Tasks::CompleteTask.call(@task.id)

    assert result.success?
    new_task = Task.where.not(id: @task.id).last
    assert_in_delta (@task.due_date + 7.days).to_i, new_task.due_date.to_i, 1
  end

  test "recreates monthly recurring task" do
    @task.update!(is_recurring: true, recurring_interval: "monthly")
    result = Tasks::CompleteTask.call(@task.id)

    assert result.success?
    new_task = Task.where.not(id: @task.id).last
    assert_in_delta (@task.due_date + 1.month).to_i, new_task.due_date.to_i, 1
  end

  test "copies tags to recurring task" do
    tag = Tag.create!(name: "projeto")
    @task.tags << tag
    @task.update!(is_recurring: true, recurring_interval: "daily")

    result = Tasks::CompleteTask.call(@task.id)
    new_task = Task.where.not(id: @task.id).last
    assert_includes new_task.tags, tag
  end

  test "does not recreate if recurring_interval is blank" do
    @task.update!(is_recurring: true, recurring_interval: nil)
    result = Tasks::CompleteTask.call(@task.id)

    assert result.success?
    assert_equal 1, Task.count
  end

  test "fails for non-existent task" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Tasks::CompleteTask.call(-1)
    end
  end
end
