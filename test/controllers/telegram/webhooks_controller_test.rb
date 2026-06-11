require "test_helper"

class TelegramWebhooksControllerTest < ActionDispatch::IntegrationTest
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200, body: { ok: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  test "POST webhook enqueues job" do
    assert_enqueued_with(job: ProcessTelegramMessageJob) do
      post telegram_webhook_path, params: {
        update_id: 12345,
        message: { chat: { id: 111 }, text: "criar reuniao" }
      }, as: :json
    end

    assert_response :ok
  end

  test "POST webhook stores telegram message" do
    assert_difference "TelegramMessage.count", 1 do
      post telegram_webhook_path, params: {
        update_id: 54321,
        message: { chat: { id: 222 }, text: "ola mundo" }
      }, as: :json
    end

    msg = TelegramMessage.find_by(update_id: 54321)
    assert_equal 222, msg.chat_id
    assert_equal "ola mundo", msg.text
  end

  test "POST webhook handles voice message" do
    assert_difference "TelegramMessage.count", 1 do
      post telegram_webhook_path, params: {
        update_id: 99999,
        message: { chat: { id: 333 }, voice: { file_id: "voice_123" } }
      }, as: :json
    end

    msg = TelegramMessage.find_by(update_id: 99999)
    assert_equal "voice_123", msg.voice_file_id
  end

  test "POST webhook returns 200 even on duplicate update_id" do
    TelegramMessage.create!(chat_id: 999, update_id: 11111, text: "existing")

    assert_no_difference "TelegramMessage.count" do
      post telegram_webhook_path, params: {
        update_id: 11111,
        message: { chat: { id: 444 }, text: "teste" }
      }, as: :json
    end

    assert_response :ok
  end
end
