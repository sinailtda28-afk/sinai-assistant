module NLP
  class TranscribeAudio < ApplicationService
    GROQ_TRANSCRIPTION_URL = "https://api.groq.com/openai/v1/audio/transcriptions"

    def initialize(file_id)
      @file_id = file_id
    end

    def call
      token = Rails.application.credentials.dig(:telegram, :bot_token)
      return Result.new(success: false, errors: ["Token do Telegram nao configurado"]) unless token

      file_url = "https://api.telegram.org/bot#{token}/getFile?file_id=#{@file_id}"
      response = Net::HTTP.get(URI(file_url))
      file_info = JSON.parse(response)

      unless file_info["ok"]
        return Result.new(success: false, errors: ["Falha ao obter informacoes do arquivo"])
      end

      file_path = file_info.dig("result", "file_path")
      download_url = "https://api.telegram.org/file/bot#{token}/#{file_path}"

      audio_data = Net::HTTP.get(URI(download_url))
      transcription = transcribe_with_groq(audio_data)

      Result.new(success: true, data: { text: transcription })
    rescue => e
      Result.new(success: false, errors: ["Falha na transcricao: #{e.message}"])
    end

    private

    def transcribe_with_groq(audio_data)
      groq_key = Rails.application.credentials.dig(:groq, :api_key)
      return "Chave da API Groq nao configurada" unless groq_key

      tempfile = Tempfile.new(["voice", ".ogg"])
      tempfile.binmode
      tempfile.write(audio_data)
      tempfile.rewind

      uri = URI(GROQ_TRANSCRIPTION_URL)
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{groq_key}"

      form_data = [
        ["file", tempfile, { filename: "audio.ogg", content_type: "audio/ogg" }],
        ["model", "whisper-large-v3-turbo"],
        ["language", "pt"],
        ["response_format", "json"],
        ["temperature", "0"]
      ]

      request.set_form(form_data, "multipart/form-data")
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      http.read_timeout = 120

      response = http.request(request)
      result = JSON.parse(response.body)

      if result["text"]
        result["text"]
      else
        "Nao foi possivel transcrever o audio: #{result["error"] || "erro desconhecido"}"
      end
    rescue => e
      "Nao foi possivel transcrever o audio: #{e.message}"
    ensure
      tempfile&.close!
    end
  end
end
