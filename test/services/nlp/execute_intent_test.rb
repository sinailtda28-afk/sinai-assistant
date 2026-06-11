require "test_helper"

class NLPExecuteIntentTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @task = Task.create!(title: "Reuniao fornecedor", column: @column)
    @chat_id = 12345
    TelegramMessage.create!(chat_id: @chat_id, update_id: 1, text: "hello")

    stub_telegram_send
  end

  test "creates task via execute intent" do
    result = NLP::ExecuteIntent.call(
      intent: :create_task,
      entities: { title: "Nova reuniao", due_date: Date.current + 1, priority: "high" },
      chat_id: @chat_id
    )
    assert result.success?
  end

  test "completes task by title search" do
    result = NLP::ExecuteIntent.call(
      intent: :complete_task,
      entities: { title: "Reuniao" },
      chat_id: @chat_id
    )
    assert result.success?
    assert_not_nil @task.reload.completed_at
  end

  test "lists tasks" do
    result = NLP::ExecuteIntent.call(
      intent: :list_tasks,
      entities: {},
      chat_id: @chat_id
    )
    assert result.success?
  end

  test "reschedules task by title" do
    new_date = 3.days.from_now.to_date
    result = NLP::ExecuteIntent.call(
      intent: :reschedule,
      entities: { title: "Reuniao", due_date: new_date },
      chat_id: @chat_id
    )
    assert result.success?
    assert_equal new_date, @task.reload.due_date.to_date
  end

  test "sets priority on task" do
    result = NLP::ExecuteIntent.call(
      intent: :set_priority,
      entities: { title: "Reuniao", priority: "high" },
      chat_id: @chat_id
    )
    assert result.success?
    assert_equal "high", @task.reload.priority
  end

  test "queries calendar for today" do
    result = NLP::ExecuteIntent.call(
      intent: :query_calendar,
      entities: { due_date: Date.current },
      chat_id: @chat_id
    )
    assert result.success?
  end

  test "shows help text" do
    result = NLP::ExecuteIntent.call(
      intent: :help,
      entities: {},
      chat_id: @chat_id
    )
    assert result.success?
    assert_kind_of String, result.data
  end

  test "returns error for missing task on complete" do
    result = NLP::ExecuteIntent.call(
      intent: :complete_task,
      entities: { title: "TarefaInexistenteXYZ" },
      chat_id: @chat_id
    )
    assert_not result.success?
  end

  test "returns error for reschedule without date" do
    result = NLP::ExecuteIntent.call(
      intent: :reschedule,
      entities: { title: "Reuniao" },
      chat_id: @chat_id
    )
    assert_not result.success?
  end

  test "returns error for unknown intent" do
    result = NLP::ExecuteIntent.call(
      intent: :unknown_intent,
      entities: {},
      chat_id: @chat_id
    )
    assert_not result.success?
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
