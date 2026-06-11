require "test_helper"

class NotificationsDailySummaryTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @chat_id = 12345
    TelegramMessage.create!(chat_id: @chat_id, update_id: 1, text: "hello")
  end

  test "sends daily summary with tasks" do
    Task.create!(title: "Tarefa hoje", column: @column, due_date: Time.current)
    stub_telegram_send

    result = Notifications::DailySummary.call

    assert result.success?
    assert_requested(:post, %r{api\.telegram\.org}, times: 1)
  end

  test "sends daily summary with overdues" do
    Task.create!(title: "Atrasada", column: @column, due_date: 1.day.ago)
    stub_telegram_send

    result = Notifications::DailySummary.call

    assert result.success?
    assert_requested(:post, %r{api\.telegram\.org}, times: 1)
  end

  test "sends bold_italic task in summary" do
    Task.create!(title: "Importante", column: @column, due_date: Time.current)
    stub_telegram_send

    result = Notifications::DailySummary.call
    assert result.success?
  end

  test "returns error when no chat configured" do
    TelegramMessage.delete_all

    result = Notifications::DailySummary.call

    assert_not result.success?
    assert_includes result.errors.first, "No chat configured"
  end

  private

  def stub_telegram_send
    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200, body: { ok: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end
end
