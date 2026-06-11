class DailySummaryJob < ApplicationJob
  queue_as :default

  def perform
    Notifications::DailySummary.call
  end
end
