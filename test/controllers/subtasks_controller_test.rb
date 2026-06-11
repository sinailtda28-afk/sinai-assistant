require "test_helper"

class SubtasksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Principal", column: @column)
  end

  test "PATCH update toggles completion" do
    subtask = Subtask.create!(title: "Passo 1", task: @task)
    patch subtask_path(subtask), params: { subtask: { completed: "1" } }

    assert_redirected_to root_path
    assert_not_nil subtask.reload.completed_at
  end
end
