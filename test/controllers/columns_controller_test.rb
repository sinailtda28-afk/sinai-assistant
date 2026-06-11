require "test_helper"

class ColumnsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
  end

  test "PATCH update updates column" do
    patch column_path(@column), params: { column: { name: "Backlog", color: "#ff0000" } }

    assert_redirected_to root_path
    assert_equal "Backlog", @column.reload.name
    assert_equal "#ff0000", @column.color
  end

  test "PATCH update with invalid data" do
    patch column_path(@column), params: { column: { name: "" } }

    assert_redirected_to root_path
  end
end
