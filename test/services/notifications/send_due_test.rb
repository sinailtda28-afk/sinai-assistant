require "test_helper"

class NotificationsSendDueTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @chat_id = 12345
    TelegramMessage.create!(chat_id: @chat_id, update_id: 1, text: "hello")
  end

  test "sends due reminder for task" do
    task = Task.create!(title: "Reuniao", column: @column, due_date: 2.hours.from_now)
    stub_telegram_send

    result = Notifications::SendDue.call(task)

    assert result.success?
    assert_requested(:post, %r{api\.telegram\.org}, times: 1)
  end

  test "includes time in reminder message" do
    task = Task.create!(title: "Reuniao", column: @column, due_date: Time.current + 1.hour)
    stub_telegram_send

    result = Notifications::SendDue.call(task)
    assert result.success?
  end

  test "returns error without chat configured" do
    TelegramMessage.delete_all
    task = Task.create!(title: "Teste", column: @column)

    result = Notifications::SendDue.call(task)
    assert_not result.success?
  end

  private

  def stub_telegram_send
    stub_request(:post, %r{api\.telegram\.org}).to_return(
      status: 200, body: { ok: true }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end
end
