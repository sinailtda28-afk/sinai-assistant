# frozen_string_literal: true

# Error reporter that sends notifications via Telegram.
# Subscribes to Rails.error to catch unhandled exceptions.
# Falls back to Rails.logger.warn if Telegram is not configured.

return unless defined?(Telegram::SendMessage)

module ErrorReporter
  class TelegramSubscriber
    def initialize
      @chat_id = Rails.application.credentials.dig(:telegram, :error_reports_chat_id)
    end

    def report(error, handled:, severity:, context:, source: nil)
      return unless @chat_id

      message = build_message(error, handled:, severity:, context:, source:)
      Telegram::SendMessage.call(@chat_id, message)
    rescue StandardError => e
      Rails.logger.warn("Error reporter failed: #{e.message}")
    end

    private

    def build_message(error, handled:, severity:, context:, source:)
      emoji = handled ? "⚠" : "🚨"
      env = Rails.env

      <<~MSG.strip
        #{emoji} [#{env}] #{severity&.to_s&.upcase || "ERROR"}
        #{error.class}: #{error.message}
        #{source ? "Source: #{source}" : ""}
        #{context.present? ? "Context: #{context.inspect.truncate(200)}" : ""}
      MSG
    end
  end
end

# Subscribe to Rails error reporter
Rails.error.subscribe(ErrorReporter::TelegramSubscriber.new)

Rails.application.config.after_initialize do
  Rails.logger.info("Error reporter subscribed — Telegram notifications active")
end
