require "test_helper"

class ColumnsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
  end

  test "POST create creates column" do
    assert_difference "Column.count", 1 do
      post columns_path, params: { column: { name: "Nova Coluna", color: "#ff0000" } }
    end
    assert_redirected_to root_path
    assert_equal "Coluna criada", flash[:notice]
  end

  test "POST create with invalid data" do
    post columns_path, params: { column: { name: "" } }
    assert_redirected_to root_path
    assert flash[:alert]
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

  test "DELETE destroy removes column" do
    assert_difference "Column.count", -1 do
      delete column_path(@column)
    end
    assert_redirected_to root_path
  end
end
