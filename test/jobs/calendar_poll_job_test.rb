require "test_helper"

class CalendarPollJobTest < ActiveJob::TestCase
  test "calls calendar sync service" do
    Calendar::SyncInbound.expects(:call).returns(
      ApplicationService::Result.new(success: true)
    )

    CalendarPollJob.perform_now
  end
end
