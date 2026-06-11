# frozen_string_literal: true

return unless defined?(RubyLLM)

RubyLLM.configure do |config|
  config.deepseek_api_key = Rails.application.credentials.dig(:ai, :deepseek_api_key)
  config.default_model = "deepseek-chat"
end

Rails.application.config.after_initialize do
  if defined?(RubyLLM::Chat)
    Rails.logger.info("RubyLLM configurado com sucesso")
  end
rescue => e
  Rails.logger.warn("RubyLLM configuracao falhou: #{e.message}")
end
