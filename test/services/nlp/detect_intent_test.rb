require "test_helper"

class NLPDetectIntentTest < ActiveSupport::TestCase
  test "detects create_task from criar" do
    result = NLP::DetectIntent.call("criar reuniao amanha")
    assert result.success?
    assert_equal :create_task, result.data[:intent]
  end

  test "detects create_task from adicionar" do
    result = NLP::DetectIntent.call("adicionar comprar leite")
    assert_equal :create_task, result.data[:intent]
  end

  test "detects create_task from preciso fazer" do
    result = NLP::DetectIntent.call("preciso fazer relatorio hoje")
    assert_equal :create_task, result.data[:intent]
  end

  test "detects complete_task from concluir" do
    result = NLP::DetectIntent.call("concluir reuniao com fornecedor")
    assert_equal :complete_task, result.data[:intent]
  end

  test "detects complete_task from finalizar" do
    result = NLP::DetectIntent.call("finalizar entregas de hoje")
    assert_equal :complete_task, result.data[:intent]
  end

  test "detects list_tasks from listar" do
    result = NLP::DetectIntent.call("listar tarefas de hoje")
    assert_equal :list_tasks, result.data[:intent]
  end

  test "detects list_tasks from o que tenho" do
    result = NLP::DetectIntent.call("o que tenho para hoje")
    assert_equal :list_tasks, result.data[:intent]
  end

  test "detects reschedule from reagendar" do
    result = NLP::DetectIntent.call("reagendar reuniao para sexta")
    assert_equal :reschedule, result.data[:intent]
  end

  test "detects set_priority from urgente" do
    result = NLP::DetectIntent.call("urgente relatorio financeiro")
    assert_equal :set_priority, result.data[:intent]
  end

  test "detects query_calendar from agenda" do
    result = NLP::DetectIntent.call("o que tenho essa semana")
    assert_includes [:query_calendar, :list_tasks], result.data[:intent]
  end

  test "fallback to create_task for unrecognized text" do
    result = NLP::DetectIntent.call("qualquer coisa aleatoria")
    assert_equal :create_task, result.data[:intent]
  end
end
