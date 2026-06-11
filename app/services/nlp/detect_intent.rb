module NLP
  class DetectIntent < ApplicationService
    INTENTS = %w[create_task complete_task list_tasks reschedule set_priority query_calendar help]

    def initialize(text)
      @text = text
    end

    def call
      text_lower = @text.downcase

      intent = case text_lower
      when /^(criar|adicionar|nova|novo|preciso fazer|colocar|marcar)\b/
        :create_task
      when /^(concluir|completar|finalizar|feito|done|terminar)\b/
        :complete_task
      when /^(listar|mostrar|o que tenho|quais|lista|quero ver|exibir)\b/
        :list_tasks
      when /^(reagendar|remarcar|mover|adiar|empurrar|transferir)\b/
        :reschedule
      when /^(priorizar|urgente|importante|prioridade)\b/
        :set_priority
      when /(o que tenho|agenda|calendario|compromisso|hoje|amanha|semana|mes)\b/
        :query_calendar
      else
        llm_detect
      end

      Result.new(success: true, data: { intent: intent, text: @text })
    rescue => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def llm_detect
      return :create_task unless defined?(RubyLLM::Chat)

      chat = RubyLLM.chat(model: "deepseek-chat")
      response = chat.ask(
        "Classifique a intencao do usuario em portugues. " \
        "Responda apenas com uma palavra: create_task, complete_task, list_tasks, " \
        "reschedule, set_priority, query_calendar, ou help.\n\nTexto: #{@text}"
      )

      intent = response.content.strip.to_sym
      INTENTS.include?(intent.to_s) ? intent : :create_task
    rescue
      :create_task
    end
  end
end
