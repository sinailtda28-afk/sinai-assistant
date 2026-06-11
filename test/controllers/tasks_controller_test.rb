require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @column2 = Column.create!(name: "Em Andamento", position: 1)
    Column.create!(name: "Concluido", position: 2)
  end

  test "GET index shows kanban board" do
    get root_path
    assert_response :success
    assert_select "body"
  end

  test "GET index with priority filter" do
    Task.create!(title: "Urgente", column: @column, priority: :high)
    Task.create!(title: "Normal", column: @column, priority: :medium)

    get root_path, params: { priority: "high" }
    assert_response :success
  end

  test "GET index with tag filter" do
    tag = Tag.create!(name: "financas")
    task = Task.create!(title: "Financeiro", column: @column)
    task.tags << tag

    Task.create!(title: "Outro", column: @column)

    get root_path, params: { tag: "financas" }
    assert_response :success
  end

  test "GET index with date range filter" do
    get root_path, params: { start_date: "2026-06-01", end_date: "2026-06-30" }
    assert_response :success
  end

  test "POST create creates task" do
    assert_difference "Task.count", 1 do
      post tasks_path, params: { task: { title: "Nova tarefa", priority: "medium" } }
    end
    assert_redirected_to root_path
    assert_equal "Tarefa criada com sucesso", flash[:notice]
  end

  test "POST create with invalid data" do
    post tasks_path, params: { task: { title: "" } }
    assert_redirected_to root_path
    assert flash[:alert]
  end

  test "PATCH update updates task" do
    task = Task.create!(title: "Original", column: @column)
    patch task_path(task), params: { task: { title: "Atualizada" } }

    assert_redirected_to root_path
    assert_equal "Tarefa atualizada", flash[:notice]
    assert_equal "Atualizada", task.reload.title
  end

  test "DELETE destroy deletes task" do
    task = Task.create!(title: "Remover", column: @column)
    assert_difference "Task.count", -1 do
      delete task_path(task)
    end
    assert_redirected_to root_path
  end

  test "POST move moves task to column" do
    task = Task.create!(title: "Mover", column: @column, position: 0)
    post move_task_path(task), params: { to_column_id: @column2.id, position: 0 }

    assert_response :ok
    assert_equal @column2, task.reload.column
  end

  test "POST move with invalid column" do
    task = Task.create!(title: "Mover", column: @column)
    post move_task_path(task), params: { to_column_id: -1, position: 0 }

    assert_response :not_found
  end
end
