class TelegramMessage < ApplicationRecord
  validates :update_id, presence: true, uniqueness: true
  validates :chat_id, presence: true
  validates :status, presence: true

  scope :pending, -> { where(status: "received") }
  scope :completed, -> { where(status: "completed") }
end
