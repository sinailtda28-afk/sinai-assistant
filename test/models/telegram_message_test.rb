require "test_helper"

class TelegramMessageTest < ActiveSupport::TestCase
  test "valid with required fields" do
    msg = TelegramMessage.new(chat_id: 123, update_id: 456, text: "ola")
    assert msg.valid?
  end

  test "invalid without chat_id" do
    msg = TelegramMessage.new(update_id: 456, text: "ola")
    assert_not msg.valid?
  end

  test "invalid without update_id" do
    msg = TelegramMessage.new(chat_id: 123, text: "ola")
    assert_not msg.valid?
  end

  test "update_id is unique" do
    TelegramMessage.create!(chat_id: 123, update_id: 456, text: "ola")
    duplicate = TelegramMessage.new(chat_id: 123, update_id: 456, text: "outro")
    assert_not duplicate.valid?
  end

  test "default status is received" do
    msg = TelegramMessage.new(chat_id: 123, update_id: 789, text: "teste")
    assert_equal "received", msg.status
  end

  test "can store voice_file_id" do
    msg = TelegramMessage.create!(chat_id: 123, update_id: 999, voice_file_id: "AwADBAAD")
    assert_equal "AwADBAAD", msg.voice_file_id
  end

  test "can store raw_payload" do
    payload = '{"message":{"text":"ola","chat":{"id":123}}}'
    msg = TelegramMessage.create!(chat_id: 123, update_id: 1000, text: "ola", raw_payload: payload)
    assert_equal payload, msg.raw_payload
  end

  test "can store intent and confidence" do
    msg = TelegramMessage.create!(
      chat_id: 123, update_id: 1001, text: "criar reuniao",
      intent: "create_task", confidence: 0.95
    )
    assert_equal "create_task", msg.intent
    assert_equal 0.95, msg.confidence
  end
end
