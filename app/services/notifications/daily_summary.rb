module Notifications
  class DailySummary < ApplicationService
    def call
      chat_id = find_chat_id
      return Result.new(success: false, errors: ["No chat configured"]) unless chat_id

      tasks_today = Task.pending.parent_tasks.where(due_date: Date.current.all_day)
      overdue = Task.pending.parent_tasks.overdue

      lines = ["☀️ Bom dia! Resumo do dia:"]
      lines << ""

      if tasks_today.any?
        lines << "📋 Hoje você tem #{tasks_today.size} tarefa(s):"
        tasks_today.each { |t| lines << "  • #{t.title}#{t.due_date ? " #{t.due_date.strftime('%H:%M')}" : ''}" }
      else
        lines << "📋 Nenhuma tarefa para hoje"
      end

      if overdue.any?
        lines << ""
        lines << "⚠️ #{overdue.size} tarefa(s) atrasada(s):"
        overdue.each { |t| lines << "  • #{t.title}" }
      end

      Telegram::SendMessage.call(chat_id, lines.join("\n"))
      Result.new(success: true)
    end

    private

    def find_chat_id
      msg = TelegramMessage.where.not(chat_id: nil).last
      msg&.chat_id
    end
  end
end
