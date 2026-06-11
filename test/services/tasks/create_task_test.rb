require "test_helper"

class TasksCreateTaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
  end

  test "creates task with title in first column" do
    result = Tasks::CreateTask.call(title: "Nova tarefa")

    assert result.success?
    assert_equal "Nova tarefa", result.data.title
    assert_equal @column, result.data.column
    assert_equal 1, result.data.position
  end

  test "creates task in specified column" do
    other = Column.create!(name: "Em Andamento", position: 1)
    result = Tasks::CreateTask.call(title: "Task", column_id: other.id)

    assert result.success?
    assert_equal other, result.data.column
  end

  test "creates task with due_date and priority" do
    date = 1.day.from_now
    result = Tasks::CreateTask.call(title: "Entrega", due_date: date, priority: "high")

    assert result.success?
    assert_in_delta date.to_i, result.data.due_date.to_i, 1
    assert_equal "high", result.data.priority
  end

  test "resolves new tags" do
    result = Tasks::CreateTask.call(title: "Financeiro", tags: ["projeto", "urgente"])

    assert result.success?
    assert_equal 2, result.data.tags.count
    assert_equal ["projeto", "urgente"], result.data.tags.pluck(:name).sort
  end

  test "reuses existing tags" do
    Tag.create!(name: "projeto")
    result = Tasks::CreateTask.call(title: "Teste", tags: ["projeto"])

    assert result.success?
    assert_equal 1, Tag.count
  end

  test "strips and downcases tag names" do
    result = Tasks::CreateTask.call(title: "Teste", tags: ["  IMPORTANTE  "])

    assert result.success?
    assert_equal "importante", result.data.tags.first.name
  end

  test "increments position" do
    Tasks::CreateTask.call(title: "First")
    result = Tasks::CreateTask.call(title: "Second")

    assert_equal 2, result.data.position
  end

  test "fails without title" do
    result = Tasks::CreateTask.call(title: nil)

    assert_not result.success?
    assert result.errors.any? { |e| e.include?("Title") }
  end

  test "fails with invalid column_id" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Tasks::CreateTask.call(title: "Test", column_id: -1)
    end
  end
end
