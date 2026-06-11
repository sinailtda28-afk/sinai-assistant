require "test_helper"

class ColumnTest < ActiveSupport::TestCase
  test "valid with name" do
    column = Column.new(name: "A Fazer", position: 0)
    assert column.valid?
  end

  test "invalid without name" do
    column = Column.new(position: 0)
    assert_not column.valid?
    assert_includes column.errors[:name], "can't be blank"
  end

  test "has many tasks" do
    column = Column.create!(name: "Backlog", position: 0)
    task = Task.create!(title: "Tarefa", column: column)

    assert_includes column.tasks, task
  end

  test "default color is set" do
    column = Column.create!(name: "Teste", position: 0)
    assert_equal "#6b7280", column.color
  end

  test "ordered scope returns by position" do
    c1 = Column.create!(name: "First", position: 2)
    c2 = Column.create!(name: "Second", position: 0)
    c3 = Column.create!(name: "Third", position: 1)

    ordered = Column.ordered
    assert_equal [c2, c3, c1], ordered.to_a
  end
end
