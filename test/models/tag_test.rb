require "test_helper"

class TagTest < ActiveSupport::TestCase
  test "valid with name" do
    tag = Tag.new(name: "importante")
    assert tag.valid?
  end

  test "invalid without name" do
    tag = Tag.new
    assert_not tag.valid?
    assert_includes tag.errors[:name], "can't be blank"
  end

  test "name is unique case-insensitive" do
    Tag.create!(name: "importante")
    duplicate = Tag.new(name: "importante")
    assert_not duplicate.valid?
  end

  test "has many tasks through task_tags" do
    column = Column.create!(name: "Todo", position: 0)
    tag = Tag.create!(name: "projeto")
    task = Task.create!(title: "Task 1", column: column)
    task.tags << tag

    assert_includes tag.tasks.reload, task
  end
end
