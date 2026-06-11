require "test_helper"

class ConversationStateTest < ActiveSupport::TestCase
  test "valid with chat_id" do
    state = ConversationState.new(chat_id: 12345, state: "idle")
    assert state.valid?
  end

  test "invalid without chat_id" do
    state = ConversationState.new(state: "idle")
    assert_not state.valid?
    assert_includes state.errors[:chat_id], "can't be blank"
  end

  test "chat_id is unique" do
    ConversationState.create!(chat_id: 12345, state: "idle")
    duplicate = ConversationState.new(chat_id: 12345, state: "idle")
    assert_not duplicate.valid?
  end

  test "default state is idle" do
    state = ConversationState.new(chat_id: 99999)
    assert_equal "idle", state.state
  end

  test "idle? returns true when state is idle" do
    state = ConversationState.new(chat_id: 123, state: "idle")
    assert state.idle?
  end

  test "idle? returns false when state is not idle" do
    state = ConversationState.new(chat_id: 123, state: "awaiting_confirmation")
    assert_not state.idle?
  end

  test "for_chat finds or initializes" do
    existing = ConversationState.create!(chat_id: 555, state: "idle")
    found = ConversationState.for_chat(555)
    assert_equal existing, found
  end

  test "for_chat initializes new record" do
    state = ConversationState.for_chat(777)
    assert state.new_record?
    assert_equal 777, state.chat_id
    assert_equal "idle", state.state
  end

  test "mark_idle! sets state to idle" do
    state = ConversationState.create!(chat_id: 888, state: "awaiting_confirmation")
    state.mark_idle!
    assert_equal "idle", state.reload.state
  end
end
