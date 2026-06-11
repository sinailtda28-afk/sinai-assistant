require "test_helper"

class TasksUpdateTaskTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @other_column = Column.create!(name: "Em Andamento", position: 1)
    @task = Task.create!(title: "Tarefa original", column: @column)
  end

  test "updates task title" do
    result = Tasks::UpdateTask.call(@task.id, title: "Novo titulo")

    assert result.success?
    assert_equal "Novo titulo", result.data.title
  end

  test "updates task description and priority" do
    result = Tasks::UpdateTask.call(@task.id, description: "Descricao longa", priority: "high")

    assert result.success?
    assert_equal "Descricao longa", result.data.description
    assert_equal "high", result.data.priority
  end

  test "moves task to different column" do
    result = Tasks::UpdateTask.call(@task.id, column_id: @other_column.id)

    assert result.success?
    assert_equal @other_column, result.data.column
    assert_equal 1, result.data.position
  end

  test "updates tags replacing old ones" do
    tag = Tag.create!(name: "antiga")
    @task.tags << tag

    result = Tasks::UpdateTask.call(@task.id, tags: ["nova"])

    assert result.success?
    assert_equal ["nova"], result.data.tags.reload.pluck(:name)
  end

  test "strips and downcases tags" do
    result = Tasks::UpdateTask.call(@task.id, tags: ["  URGENTE  "])

    assert result.success?
    assert_equal "urgente", result.data.tags.first.name
  end

  test "fails for non-existent task" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Tasks::UpdateTask.call(-1, title: "Teste")
    end
  end

  test "fails with invalid column_id" do
    result = Tasks::UpdateTask.call(@task.id, column_id: -1)
    assert_not result.success?
  end
end
