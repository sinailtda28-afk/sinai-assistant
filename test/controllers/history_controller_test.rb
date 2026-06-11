require "test_helper"

class HistoryControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
  end

  test "GET history index" do
    Task.create!(title: "Concluida", column: @column, completed_at: 1.day.ago)
    Task.create!(title: "Pendente", column: @column)

    get history_path
    assert_response :success
  end

  test "GET history with no completed tasks" do
    get history_path
    assert_response :success
  end
end
