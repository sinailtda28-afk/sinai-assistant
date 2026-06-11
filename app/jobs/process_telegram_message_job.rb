class ProcessTelegramMessageJob < ApplicationJob
  queue_as :default

  def perform(update_id)
    message = TelegramMessage.find_by!(update_id: update_id)
    Telegram::ProcessMessage.call(message)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Telegram message #{update_id} not found — skipping")
  end
end
