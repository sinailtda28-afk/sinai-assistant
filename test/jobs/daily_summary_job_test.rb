require "test_helper"

class DailySummaryJobTest < ActiveJob::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    TelegramMessage.create!(chat_id: 12345, update_id: 1, text: "hello")

    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200, body: { ok: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  test "calls daily summary service" do
    Notifications::DailySummary.expects(:call).returns(
      ApplicationService::Result.new(success: true)
    )

    DailySummaryJob.perform_now
  end
end
