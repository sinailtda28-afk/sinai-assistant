module Telegram
  class ProcessMessage < ApplicationService
    def initialize(message)
      @message = message
      @chat_id = message.chat_id
      @text = message.text
    end

    def call
      @message.update!(status: "processing")

      # Voice message handling
      if @message.voice_file_id.present?
        reply("🎤 Transcrevendo áudio...")
        transcription = NLP::TranscribeAudio.call(@message.voice_file_id)

        if transcription.success?
          @text = transcription.data[:text]
          reply("Transcrito: \"#{@text}\"")
        else
          @message.update!(status: "failed")
          reply("❌ Não foi possível transcrever o áudio.")
          return Result.new(success: false, errors: transcription.errors)
        end
      end

      if @text.blank?
        reply("Por favor, envie uma mensagem de texto ou áudio.")
        @message.update!(status: "failed")
        return Result.new(success: false, errors: ["Empty message"])
      end

      # Conversation state check
      state = ConversationState.for_chat(@chat_id)

      if !state.new_record? && !state.idle?
        return handle_state(state)
      end

      # NLP Pipeline
      result = NLP::Pipeline.call(@text, chat_id: @chat_id)

      if result.success?
        @message.update!(status: "completed")
      else
        @message.update!(status: "failed")
      end

      result
    rescue => e
      @message.update!(status: "failed")
      reply("❌ Erro ao processar: #{e.message}")
      Result.new(success: false, errors: [e.message])
    end

    private

    def handle_state(state)
      case state.state
      when "awaiting_confirmation" then handle_confirmation(state)
      when "collecting_due" then handle_collecting_due(state)
      when "collecting_priority" then handle_collecting_priority(state)
      else
        state.mark_idle!
        NLP::Pipeline.call(@text, chat_id: @chat_id)
      end
    end

    def handle_collecting_due(state)
      entities_result = NLP::ExtractEntities.call(@text, intent: state.pending_intent&.to_sym || :create_task)
      due_date = entities_result.data[:due_date]

      unless due_date
        reply("📅 Nao entendi a data. Tente: amanha, sexta-feira, dia 15/06")
        return Result.new(success: true, data: { action: :prompt_due })
      end

      data = JSON.parse(state.pending_data || "{}").transform_keys(&:to_sym)
      data[:due_date] = due_date.to_s

      entities_result = NLP::ExtractEntities.call("#{data[:title]} #{@text}", intent: :create_task)
      priority = entities_result.data[:priority]

      if priority && priority != "medium"
        data[:priority] = priority
        state.mark_idle!
        result = NLP::ExecuteIntent.call(intent: :create_task, entities: data, chat_id: @chat_id)
        result
      else
        state.set_pending(:create_task, data.merge(state: :collecting_priority))
        reply("⚡ Qual a prioridade? (alta, media, baixa)")
        Result.new(success: true, data: { action: :prompt_priority })
      end
    rescue => e
      state.mark_idle!
      reply("❌ Erro: #{e.message}")
      Result.new(success: false, errors: [e.message])
    end

    def handle_collecting_priority(state)
      entities_result = NLP::ExtractEntities.call(@text, intent: :set_priority)
      priority = entities_result.data[:priority] || extract_priority_from_text(@text)

      unless priority
        reply("⚡ Nao entendi. Responda: alta, media ou baixa")
        return Result.new(success: true, data: { action: :prompt_priority })
      end

      data = JSON.parse(state.pending_data || "{}").transform_keys(&:to_sym)
      data[:priority] = priority
      state.mark_idle!

      result = NLP::ExecuteIntent.call(intent: :create_task, entities: data, chat_id: @chat_id)
      result
    rescue => e
      state.mark_idle!
      reply("❌ Erro: #{e.message}")
      Result.new(success: false, errors: [e.message])
    end

    def extract_priority_from_text(text)
      case text.downcase
      when /\b(alta|urgente|importante|1)\b/ then "high"
      when /\b(media|normal|2)\b/ then "medium"
      when /\b(baixa|baixo|tranquilo|3)\b/ then "low"
      end
    end

    def handle_confirmation(state)
      if @text.downcase.match?(/\b(sim|ok|yes|pode ser|confirmo|isso)\b/)
        data = JSON.parse(state.pending_data || "{}").transform_keys(&:to_sym)
        intent = state.pending_intent&.to_sym

        result = NLP::ExecuteIntent.call(intent: intent, entities: data, chat_id: @chat_id)
        state.mark_idle!
        result
      else
        state.mark_idle!
        reply("Ok, comando cancelado. Envie uma nova mensagem quando precisar.")
        Result.new(success: true, data: { action: "cancelled" })
      end
    rescue => e
      state.mark_idle!
      reply("❌ Erro: #{e.message}")
      Result.new(success: false, errors: [e.message])
    end

    def reply(text)
      Telegram::SendMessage.call(@chat_id, text)
    end
  end
end
