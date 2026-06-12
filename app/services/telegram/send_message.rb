# frozen_string_literal: true

module Telegram
  # Sends a message via the Telegram Bot API.
  # Uses the bot token from Rails credentials.
  # Returns the Telegram API response on success, or logs error on failure.
  class SendMessage < ApplicationService
    TELEGRAM_API = "https://api.telegram.org/bot"

    def initialize(chat_id, text, parse_mode: nil)
      @chat_id = chat_id
      @text = text
      @parse_mode = parse_mode
    end

    def call
      token = ENV.fetch("TELEGRAM_BOT_TOKEN", nil) ||
              Rails.application.credentials.dig(:telegram, :bot_token) ||
              Setting.get("telegram_bot_token")
      return log_missing_token unless token

      uri = URI("#{TELEGRAM_API}#{token}/sendMessage")
      response = Net::HTTP.post(
        uri,
        { chat_id: @chat_id, text: @text, parse_mode: @parse_mode }.compact.to_json,
        "Content-Type" => "application/json"
      )

      if response.is_a?(Net::HTTPSuccess)
        Result.new(success: true, data: JSON.parse(response.body))
      else
        Result.new(success: false, errors: ["Telegram API error: #{response.code} - #{response.body}"])
      end
    rescue StandardError => e
      Result.new(success: false, errors: ["Telegram send error: #{e.message}"])
    end

    private

    def log_missing_token
      Rails.logger.warn("Telegram bot token not configured in credentials")
      Result.new(success: false, errors: ["Missing bot token"])
    end
  end
end
