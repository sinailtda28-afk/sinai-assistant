require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
  end

  test "GET dashboard index" do
    Task.create!(title: "Tarefa 1", column: @column)
    Task.create!(title: "Tarefa 2", column: @column, completed_at: Time.current)

    get dashboard_path
    assert_response :success
  end

  test "GET dashboard with no tasks" do
    get dashboard_path
    assert_response :success
  end
end
