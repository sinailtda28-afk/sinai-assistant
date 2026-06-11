module Notifications
  class SetupReminders < ApplicationService
    def initialize(task)
      @task = task
    end

    def call
      return Result.new(success: true, data: { skipped: true }) unless @task.due_date

      settings = NotificationSetting.find_by(channel: "telegram")
      minutes = settings&.reminder_minutes || 30
      remind_at = @task.due_date - minutes.minutes

      ReminderJob.set(wait_until: remind_at).perform_later(@task.id)

      Result.new(success: true, data: { scheduled_at: remind_at })
    end
  end
end
