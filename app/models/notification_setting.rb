class NotificationSetting < ApplicationRecord
  validates :channel, presence: true, uniqueness: true
  validates :reminder_minutes, numericality: { in: [5, 120] }
end
