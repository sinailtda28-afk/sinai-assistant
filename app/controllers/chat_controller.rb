class ChatController < ApplicationController
  def ask
    message = params[:message].to_s.strip
    return render json: { error: "Mensagem vazia" }, status: 422 if message.blank?

    begin
      context = build_context
      chat = RubyLLM.chat(model: "deepseek-chat").with_instructions(context)
      response = chat.ask(message)

      render json: { reply: response.content }
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  def analyze
    tasks = Task.pending.parent_tasks.includes(:tags, :column).order(:due_date)
    overdue = Task.overdue
    ai_context = Setting.find_by(key: "ai_context")&.value

    created_month = Task.where(created_at: Date.current.beginning_of_month..Time.current).count
    completed_month = Task.completed.where(completed_at: Date.current.beginning_of_month..Time.current).count
    rate = created_month > 0 ? (completed_month.to_f / created_month * 100).round(1) : 0
    overdue_count = overdue.count
    high = tasks.where(priority: :high).count
    medium = tasks.where(priority: :medium).count
    low = tasks.where(priority: :low).count

    prompt = "Analise a produtividade do usuario com base nestes dados:\n"
    prompt += "- Tarefas criadas este mes: #{created_month}\n"
    prompt += "- Tarefas concluidas: #{completed_month}\n"
    prompt += "- Taxa de conclusao: #{rate}%\n"
    prompt += "- Tarefas atrasadas: #{overdue_count}\n"
    prompt += "- Por prioridade: Alta=#{high}, Media=#{medium}, Baixa=#{low}\n"
    prompt += "- Total pendentes: #{tasks.count}\n\n"
    prompt += "De sugestoes praticas e acionaveis para melhorar a produtividade. "

    if ai_context.present?
      prompt += "Contexto adicional: #{ai_context}. "
    end
    prompt += "Responda em portugues brasileiro, tom motivacional e util, maximo 4 paragrafos."

    begin
      chat = RubyLLM.chat(model: "deepseek-chat")
      response = chat.ask(prompt)
      render json: { analysis: response.content }
    rescue => e
      render json: { error: e.message }, status: 500
    end
  end

  private

  def build_context
    tasks = Task.pending.parent_tasks.includes(:tags, :column).order(:due_date)
    overdue = Task.overdue
    ai_context = Setting.find_by(key: "ai_context")&.value

    context = ""
    if ai_context.present?
      context += "#{ai_context}\n\n"
    else
      context += "Voce e um assistente de produtividade pessoal. Ajude o usuario a gerenciar tarefas.\n\n"
    end
    context += "=== TAREFAS DO USUARIO ===\n"

    if tasks.any?
      tasks.each do |t|
        line = "• #{t.title}"
        line += " | Prazo: #{t.due_date.strftime('%d/%m/%Y')}" if t.due_date
        line += " | Prioridade: #{t.priority}"
        line += " | Tags: #{t.tags.map(&:name).join(', ')}" if t.tags.any?
        line += " | Coluna: #{t.column.name}"
        context += line + "\n"
      end
    else
      context += "Nenhuma tarefa pendente.\n"
    end

    if overdue.any?
      context += "\n⚠️ TAREFAS ATRASADAS:\n"
      overdue.each { |t| context += "• #{t.title}\n" }
    end

    context += "\nResponda de forma concisa e util em portugues brasileiro. Sugira acoes quando relevante."
    context
  end
end
