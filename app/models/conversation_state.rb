class ConversationState < ApplicationRecord
  validates :chat_id, presence: true, uniqueness: true
  validates :state, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }

  def self.for_chat(chat_id)
    find_or_initialize_by(chat_id: chat_id)
  end

  def idle?
    state == "idle"
  end

  def mark_idle!
    update!(state: "idle", pending_intent: nil, pending_data: nil, expires_at: nil)
  end

  def set_pending(intent, data = {})
    custom_state = data.delete(:state) || data.delete("state") || "awaiting_confirmation"
    update!(
      state: custom_state,
      pending_intent: intent.to_s,
      pending_data: data.to_json,
      expires_at: 10.minutes.from_now
    )
  end
end
