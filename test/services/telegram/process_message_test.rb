require "test_helper"

class TelegramProcessMessageTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @chat_id = 12345
    @message = TelegramMessage.create!(chat_id: @chat_id, update_id: 100, text: "criar reuniao amanha")
    stub_telegram_send
  end

  test "processes text message through NLP pipeline" do
    result = Telegram::ProcessMessage.call(@message)

    assert result.success?
    assert_equal "completed", @message.reload.status
  end

  test "handles empty text message" do
    @message.update!(text: "")
    result = Telegram::ProcessMessage.call(@message)

    assert_not result.success?
    assert_equal "failed", @message.reload.status
  end

  test "handles nil text message" do
    @message.update!(text: nil)
    result = Telegram::ProcessMessage.call(@message)

    assert_not result.success?
    assert_equal "failed", @message.reload.status
  end

  test "handles awaiting_confirmation state with sim" do
    state = ConversationState.create!(chat_id: @chat_id, state: "idle")
    state.set_pending(:create_task, { title: "Teste confirmado", due_date: nil, priority: "medium" })

    @message.update!(text: "sim")
    result = Telegram::ProcessMessage.call(@message)

    assert result.success?
    assert_equal "idle", state.reload.state
    assert_nil state.pending_intent
  end

  test "handles awaiting_confirmation state with cancel" do
    state = ConversationState.create!(chat_id: @chat_id, state: "idle")
    state.set_pending(:create_task, { title: "Teste" })

    @message.update!(text: "nao quero")
    result = Telegram::ProcessMessage.call(@message)

    assert result.success?
    assert_equal "idle", state.reload.state
    assert_equal "cancelled", result.data[:action]
  end

  test "handles voice message with empty transcription fallback" do
    @message.update!(voice_file_id: "fake_file_id", text: nil)
    NLP::TranscribeAudio.stubs(:call).returns(
      ApplicationService::Result.new(success: false, errors: ["Transcription failed"])
    )

    result = Telegram::ProcessMessage.call(@message)

    assert_not result.success?
    assert_equal "failed", @message.reload.status
  end

  test "handles voice message with successful transcription" do
    @message.update!(voice_file_id: "fake_file_id", text: nil)
    NLP::TranscribeAudio.stubs(:call).returns(
      ApplicationService::Result.new(success: true, data: { text: "criar reuniao amanha" })
    )

    result = Telegram::ProcessMessage.call(@message)

    assert result.success?
    assert_equal "completed", @message.reload.status
  end

  private

  def stub_telegram_send
    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200,
      body: { ok: true, result: { message_id: 1 } }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end
end
