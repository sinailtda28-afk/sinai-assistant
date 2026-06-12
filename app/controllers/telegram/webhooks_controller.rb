module Telegram
  class WebhooksController < ApplicationController
    skip_before_action :verify_authenticity_token

    def receive
      payload = JSON.parse(request.body.read)
      update_id = payload["update_id"]

      unless TelegramMessage.exists?(update_id: update_id)
        message = payload.dig("message") || payload.dig("edited_message")
        if message
          TelegramMessage.create!(
            update_id: update_id,
            chat_id: message.dig("chat", "id"),
            text: message["text"],
            voice_file_id: message.dig("voice", "file_id"),
            raw_payload: payload.to_json,
            status: "received"
          )
        end
      end

      if update_id
        begin
          msg = TelegramMessage.find_by!(update_id: update_id)
          Telegram::ProcessMessage.call(msg)
        rescue ActiveRecord::RecordNotFound
          Rails.logger.warn("Telegram message #{update_id} not found")
        end
      end
      head :ok
    end
  end
end
