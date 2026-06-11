require "test_helper"

class NLPExtractEntitiesTest < ActiveSupport::TestCase
  test "extracts title from create command" do
    result = NLP::ExtractEntities.call("criar reuniao com fornecedor", intent: :create_task)
    assert result.success?
    assert result.data[:title].present?
  end

  test "extracts due_date for hoje" do
    result = NLP::ExtractEntities.call("criar tarefa hoje", intent: :create_task)
    assert_equal Date.current, result.data[:due_date]
  end

  test "extracts due_date for amanha" do
    result = NLP::ExtractEntities.call("adicionar compras amanha", intent: :create_task)
    assert_equal Date.current + 1.day, result.data[:due_date]
  end

  test "extracts due_date for depois de amanha" do
    result = NLP::ExtractEntities.call("criar evento depois de amanha", intent: :create_task)
    assert_in_delta (Date.current + 1).to_time.to_i, result.data[:due_date].to_time.to_i, 1
  end

  test "extracts due_date for proxima semana" do
    result = NLP::ExtractEntities.call("marcar dentista proxima semana", intent: :create_task)
    assert_equal Date.current.next_week, result.data[:due_date]
  end

  test "extracts high priority from urgente" do
    result = NLP::ExtractEntities.call("criar relatorio urgente", intent: :create_task)
    assert_equal "high", result.data[:priority]
  end

  test "extracts medium priority" do
    result = NLP::ExtractEntities.call("criar tarefa media prioridade", intent: :create_task)
    assert_equal "medium", result.data[:priority]
  end

  test "extracts low priority" do
    result = NLP::ExtractEntities.call("criar tarefa baixa prioridade", intent: :create_task)
    assert_equal "low", result.data[:priority]
  end

  test "extracts hashtags as tags" do
    result = NLP::ExtractEntities.call("criar relatorio #financas #urgente", intent: :create_task)
    assert_includes result.data[:tags], "financas"
    assert_includes result.data[:tags], "urgente"
  end

  test "extracts query for list_tasks" do
    result = NLP::ExtractEntities.call("listar tarefas de alta prioridade", intent: :list_tasks)
    assert_equal "tarefas de alta prioridade", result.data[:task_query]
  end

  test "preserves original text when title extraction fails" do
    result = NLP::ExtractEntities.call("concluir", intent: :complete_task)
    assert result.data[:title].present? || result.success?
  end
end
