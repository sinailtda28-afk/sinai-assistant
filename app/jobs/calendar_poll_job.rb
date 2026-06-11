class CalendarPollJob < ApplicationJob
  queue_as :default

  def perform
    Calendar::SyncInbound.call
  end
end
