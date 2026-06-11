require "test_helper"

class CalendarControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
  end

  test "GET calendar index" do
    Task.create!(title: "Evento", column: @column, due_date: Date.current)
    get calendar_path
    assert_response :success
  end

  test "GET calendar day view" do
    Task.create!(title: "Hoje", column: @column, due_date: Date.current)
    get calendar_day_path
    assert_response :success
  end
end
