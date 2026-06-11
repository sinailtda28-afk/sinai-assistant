class CalendarSyncJob < ApplicationJob
  queue_as :default

  def perform(task_id, action = "upsert")
    task = Task.find_by(id: task_id)
    return unless task
    Calendar::SyncOutbound.call(task, action: action.to_sym)
  end
end
