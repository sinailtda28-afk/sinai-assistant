module NLP
  class ExtractEntities < ApplicationService
    def initialize(text, intent:)
      @text = text
      @intent = intent
    end

    def call
      entities = extract_with_regex(@text)

      if needs_llm?(entities)
        llm_entities = extract_with_llm(@text)
        entities.merge!(llm_entities) { |_, v1, v2| v1.presence || v2 }
      end

      Result.new(success: true, data: entities)
    rescue => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def extract_with_regex(text)
      entities = { title: nil, due_date: nil, priority: nil, tags: [], task_query: nil }

      # Extrair titulo (remover palavras de comando)
      title = text.sub(/^(criar|adicionar|nova|novo|preciso fazer|colocar|marcar|concluir|completar|listar|mostrar)\s+/i, "")
                  .sub(/\s+(como|com|para|em| ate| as| amanha| hoje| depois| proxima| urgente|alta|media|baixa).*/i, "")
                  .strip
      entities[:title] = title.presence

      # Extrair datas relativas
      date_map = {
        /\bhoje\b/i => Date.current,
        /\bamanha\b/i => Date.current + 1.day,
        /\bdepois de amanha\b/i => Date.current + 2.days,
        /\bproxima semana\b/i => Date.current.next_week,
        /\bproximo mes\b/i => Date.current.next_month,
        /\bfinal de semana\b/i => Date.current.end_of_week
      }

      date_map.each do |pattern, date|
        if @text.match?(pattern)
          entities[:due_date] = date
          break
        end
      end

      # Extrair prioridade
      if @text.match?(/\b(urgente|alta|alta prioridade)\b/i)
        entities[:priority] = "high"
      elsif @text.match?(/\b(media|media prioridade|normal)\b/i)
        entities[:priority] = "medium"
      elsif @text.match?(/\b(baixa|baixa prioridade|baixo)\b/i)
        entities[:priority] = "low"
      end

      # Extrair tags (#hashtag)
      entities[:tags] = @text.scan(/#(\w+)/).flatten

      # Query para list_tasks / query_calendar
      if [:list_tasks, :query_calendar].include?(@intent)
        query = text.sub(/^(listar|mostrar|o que tenho|quais|quero ver|exibir)\s+/i, "").strip
        entities[:task_query] = query.presence
      end

      entities
    end

    def needs_llm?(entities)
      entities[:title].blank?
    end

    def extract_with_llm(text)
      return {} unless defined?(RubyLLM::Chat)

      chat = RubyLLM.chat(model: "deepseek-chat")
      prompt = <<~PROMPT
        Extraia informacoes da seguinte frase em portugues brasileiro.
        Responda APENAS com JSON valido (sem markdown):
        {"title": "titulo ou null", "due_date": "ISO 8601 ou null", "priority": "high/medium/low ou null", "tags": []}
        Frase: #{text}
        Data atual: #{Date.current.iso8601}
      PROMPT

      response = chat.ask(prompt)
      JSON.parse(response.content).transform_keys(&:to_sym)
    rescue
      { title: text, due_date: nil, priority: nil, tags: [] }
    end
  end
end
