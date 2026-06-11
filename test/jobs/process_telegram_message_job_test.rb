require "test_helper"

class ProcessTelegramMessageJobTest < ActiveJob::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @message = TelegramMessage.create!(chat_id: 12345, update_id: 999, text: "criar reuniao")
    stub_telegram_send
  end

  test "processes message" do
    Telegram::ProcessMessage.expects(:call).with(@message).returns(
      ApplicationService::Result.new(success: true)
    )

    ProcessTelegramMessageJob.perform_now(@message.update_id)

    # Mocha expectation met
  end

  test "skips missing message gracefully" do
    assert_nothing_raised do
      ProcessTelegramMessageJob.perform_now(-1)
    end
  end

  private

  def stub_telegram_send
    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200, body: { ok: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end
end
