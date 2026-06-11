require "test_helper"

class ReminderJobTest < ActiveJob::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Reuniao", column: @column, due_date: 1.hour.from_now)
    TelegramMessage.create!(chat_id: 12345, update_id: 1, text: "hello")

    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200, body: { ok: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  test "sends reminder for task" do
    Notifications::SendDue.expects(:call).with(@task).returns(
      ApplicationService::Result.new(success: true)
    )

    ReminderJob.perform_now(@task.id)
  end

  test "skips missing task gracefully" do
    assert_nothing_raised do
      ReminderJob.perform_now(-1)
    end
  end
end
