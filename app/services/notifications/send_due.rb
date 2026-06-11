module Notifications
  class SendDue < ApplicationService
    def initialize(task)
      @task = task
    end

    def call
      chat_id = find_chat_id
      return Result.new(success: false, errors: ["No chat configured"]) unless chat_id

      Telegram::SendMessage.call(
        chat_id,
        "⏰ Lembrete: \"#{@task.title}\" #{@task.due_date ? @task.due_date.strftime('as %H:%M') : ''}"
      )

      Result.new(success: true)
    end

    private

    def find_chat_id
      msg = TelegramMessage.where.not(chat_id: nil).last
      msg&.chat_id
    end
  end
end
