require "test_helper"

class TasksMoveTaskTest < ActiveSupport::TestCase
  def setup
    @col1 = Column.create!(name: "A Fazer", position: 0)
    @col2 = Column.create!(name: "Em Andamento", position: 1)
    @col3 = Column.create!(name: "Concluido", position: 2)
    @task = Task.create!(title: "Mover", column: @col1, position: 0)
  end

  test "moves task to new column" do
    result = Tasks::MoveTask.call(@task.id, @col2.id)

    assert result.success?
    assert_equal @col2, result.data.column
  end

  test "moves to specific position in new column" do
    Task.create!(title: "Existing", column: @col2, position: 0)
    result = Tasks::MoveTask.call(@task.id, @col2.id, 0)

    assert result.success?
    assert_equal 0, result.data.position
  end

  test "reindexes positions after move" do
    t1 = Task.create!(title: "T1", column: @col2, position: 0)
    t2 = Task.create!(title: "T2", column: @col2, position: 1)

    result = Tasks::MoveTask.call(@task.id, @col2.id, 0)
    assert result.success?

    # After reindex: moved task at 0 pushes others down
    assert_equal 0, result.data.reload.position
    assert [1, 2].include?(t1.reload.position)
    assert [1, 2].include?(t2.reload.position)
  end

  test "fails for non-existent task" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Tasks::MoveTask.call(-1, @col2.id)
    end
  end

  test "fails for non-existent column" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Tasks::MoveTask.call(@task.id, -1)
    end
  end
end
