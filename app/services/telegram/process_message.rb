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

      if !state.new_record? && !state.idle? && state.state == "awaiting_confirmation"
        return handle_confirmation(state)
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
