require "test_helper"
require "capybara/cuprite"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, screen_size: [1400, 1400], options: { headless: true }

  def sign_in_as_chat(chat_id = 12345)
    TelegramMessage.create!(
      chat_id: chat_id,
      update_id: SecureRandom.random_number(1_000_000),
      text: "hello",
      status: "completed"
    )
    ConversationState.find_or_create_by!(chat_id: chat_id) do |cs|
      cs.state = "idle"
    end
  end
end
