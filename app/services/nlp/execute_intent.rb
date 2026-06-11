module NLP
  class ExecuteIntent < ApplicationService
    def initialize(intent:, entities:, chat_id:)
      @intent = intent
      @entities = entities
      @chat_id = chat_id
    end

    def call
      result = case @intent
      when :create_task then create_task
      when :complete_task then complete_task
      when :list_tasks then list_tasks
      when :reschedule then reschedule_task
      when :set_priority then set_priority
      when :query_calendar then query_calendar
      when :help then show_help
      else Result.new(success: false, errors: ["Intento nao reconhecido"])
      end

      send_confirmation(result)
      result
    end

    private

    def create_task
      Tasks::CreateTask.call(
        title: @entities[:title] || @entities[:task_query] || "Nova tarefa",
        due_date: @entities[:due_date],
        priority: @entities[:priority] || "medium",
        tags: @entities[:tags] || []
      )
    end

    def complete_task
      task = find_task_by_title(@entities[:title])
      return not_found_result("tarefa") unless task
      Tasks::CompleteTask.call(task.id)
    end

    def list_tasks
      tasks = Task.pending.parent_tasks
      tasks = tasks.where(priority: @entities[:priority]) if @entities[:priority]
      tasks = tasks.order(:due_date)
      success_result(tasks)
    end

    def reschedule_task
      task = find_task_by_title(@entities[:title])
      return not_found_result("tarefa") unless task
      return error_result("Data nao informada") unless @entities[:due_date]

      task.update!(due_date: @entities[:due_date])
      success_result(task)
    end

    def set_priority
      task = find_task_by_title(@entities[:title])
      return not_found_result("tarefa") unless task
      return error_result("Prioridade nao informada") unless @entities[:priority]

      task.update!(priority: @entities[:priority])
      success_result(task)
    end

    def query_calendar
      date = @entities[:due_date] || Date.current
      tasks = Task.pending.parent_tasks.where(due_date: date.all_day).order(:due_date)
      success_result(tasks)
    end

    def show_help
      help_text = "Comandos disponiveis:\n" \
                  "• Criar: \"criar tarefa amanha as 14h\"\n" \
                  "• Concluir: \"concluir reuniao\"\n" \
                  "• Listar: \"o que tenho hoje\"\n" \
                  "• Reagendar: \"mover reuniao para quinta\"\n" \
                  "• Priorizar: \"urgente tarefa X\"\n" \
                  "• Agenda: \"o que tenho essa semana\""
      success_result(help_text)
    end

    def find_task_by_title(title)
      return nil unless title
      Task.pending.parent_tasks.where("title LIKE ?", "%#{title}%").first
    end

    def not_found_result(item)
      Result.new(success: false, errors: ["#{item} nao encontrada"])
    end

    def error_result(msg)
      Result.new(success: false, errors: [msg])
    end

    def success_result(data)
      Result.new(success: true, data: data)
    end

    def send_confirmation(result)
      if result.success?
        Telegram::SendMessage.call(@chat_id, "✅ #{success_message(result)}")
      else
        error_msg = result.errors.is_a?(Array) ? result.errors.join(", ") : result.errors.to_s
        Telegram::SendMessage.call(@chat_id, "❌ #{error_msg}")
      end
    rescue => e
      Rails.logger.warn("Confirmation failed: #{e.message}")
    end

    def success_message(result)
      data = result.data
      case @intent
      when :create_task then "Tarefa criada: #{data.title}"
      when :complete_task then "Tarefa concluida: #{data.title}"
      when :list_tasks
        tasks = data
        if tasks.any?
          tasks.map { |t| "• #{t.title}#{t.due_date ? " — #{t.due_date.strftime('%d/%m')}" : ''}" }.join("\n")
        else
          "Nenhuma tarefa pendente"
        end
      when :reschedule then "Tarefa reagendada: #{data.title}"
      when :set_priority then "Prioridade atualizada: #{data.title}"
      when :query_calendar
        tasks = data
        if tasks.any?
          tasks.map { |t| "• #{t.title}#{t.due_date ? " #{t.due_date.strftime('%H:%M')}" : ''}" }.join("\n")
        else
          "Nenhum compromisso para esta data"
        end
      when :help then data.to_s
      else "Acao executada"
      end
    end
  end
end
