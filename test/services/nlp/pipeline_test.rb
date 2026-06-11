require "test_helper"

class NLPPipelineTest < ActiveSupport::TestCase
  def setup
    @column = Column.create!(name: "A Fazer", position: 0)
    @chat_id = 12345
    TelegramMessage.create!(chat_id: @chat_id, update_id: 1, text: "hello")
    stub_telegram_send
  end

  test "processes create_task through full pipeline" do
    result = NLP::Pipeline.call("criar reuniao amanha urgente", chat_id: @chat_id)
    assert result.success?
    task = Task.last
    assert task.title.present?
    assert_equal Date.current + 1.day, task.due_date.to_date
    assert_equal "high", task.priority
  end

  test "processes complete_task through pipeline" do
    task = Task.create!(title: "Estudar Ruby", column: @column)
    result = NLP::Pipeline.call("concluir estudar ruby", chat_id: @chat_id)
    assert result.success?
    assert_not_nil task.reload.completed_at
  end

  test "processes list_tasks through pipeline" do
    Task.create!(title: "Tarefa A", column: @column)
    Task.create!(title: "Tarefa B", column: @column)
    result = NLP::Pipeline.call("o que tenho hoje", chat_id: @chat_id)
    assert result.success?
  end

  test "processes reschedule through pipeline" do
    task = Task.create!(title: "mover revisar documento", column: @column)
    result = NLP::Pipeline.call("mover revisar documento para amanha", chat_id: @chat_id)
    assert result.success?
    assert_equal Date.current + 1.day, task.reload.due_date.to_date
  end

  test "processes set_priority through pipeline" do
    task = Task.create!(title: "urgente relatorio", column: @column)
    result = NLP::Pipeline.call("urgente relatorio", chat_id: @chat_id)
    assert result.success?
    assert_equal "high", task.reload.priority
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
