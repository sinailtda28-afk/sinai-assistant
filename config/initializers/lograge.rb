# frozen_string_literal: true

# Lograge configuration for structured logging.
# Filters AI responses from logs to reduce noise and protect sensitive data.

return unless defined?(Lograge)

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # Filter sensitive and verbose AI-related parameters
  config.lograge.custom_options = lambda do |event|
    {
      params: event.payload[:params]
        &.except("controller", "action", "format", "id")
        &.reject { |k, _| k.include?("ai_prompt") || k.include?("ai_response") },
      time: Time.current.iso8601
    }
  end

  config.lograge.ignore_actions = ["Rails::HealthController#show"]
end
