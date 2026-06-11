require "test_helper"

class TelegramSendMessageTest < ActiveSupport::TestCase
  test "sends message to Telegram API" do
    stub_request(:post, %r{api\.telegram\.org})
      .to_return(
        status: 200,
        body: { ok: true, result: { message_id: 42 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    result = Telegram::SendMessage.call(12345, "Ola mundo")

    assert result.success?
    assert_equal 42, result.data["result"]["message_id"]
  end

  test "handles Telegram API error response" do
    stub_request(:post, %r{api\.telegram\.org})
      .to_return(status: 403, body: "Forbidden")

    result = Telegram::SendMessage.call(12345, "teste")

    assert_not result.success?
    assert_includes result.errors.first, "Telegram API error"
  end

  test "returns missing token error without credentials" do
    Rails.application.credentials.stubs(:dig).with(:telegram, :bot_token).returns(nil)

    result = Telegram::SendMessage.call(12345, "teste")

    assert_not result.success?
    assert_includes result.errors.first, "Missing bot token"
  end

  test "handles network error" do
    stub_request(:post, %r{api\.telegram\.org}).to_raise(Errno::ECONNREFUSED)

    result = Telegram::SendMessage.call(12345, "teste")

    assert_not result.success?
    assert_includes result.errors.first, "Telegram send error"
  end

  test "includes parse_mode when provided" do
    sent_payload = nil
    stub_request(:post, %r{api\.telegram\.org})
      .with { |req| sent_payload = JSON.parse(req.body); true }
      .to_return(status: 200, body: { ok: true }.to_json,
                 headers: { "Content-Type" => "application/json" })

    Telegram::SendMessage.call(12345, "<b>bold</b>", parse_mode: "HTML")

    assert_equal "HTML", sent_payload["parse_mode"]
  end
end
