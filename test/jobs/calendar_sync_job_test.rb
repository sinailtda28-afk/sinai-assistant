require "test_helper"

class CalendarSyncJobTest < ActiveJob::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Test", column: @column)
  end

  test "calls calendar sync service with task" do
    Calendar::SyncOutbound.expects(:call).with(@task, action: :upsert).returns(
      ApplicationService::Result.new(success: true)
    )

    CalendarSyncJob.perform_now(@task.id)
  end

  test "skips missing task" do
    Calendar::SyncOutbound.expects(:call).never

    assert_nothing_raised do
      CalendarSyncJob.perform_now(-1)
    end
  end
end
