class ReminderJob < ApplicationJob
  queue_as :default

  def perform(task_id)
    task = Task.find_by(id: task_id)
    return unless task
    Notifications::SendDue.call(task)
  end
end
