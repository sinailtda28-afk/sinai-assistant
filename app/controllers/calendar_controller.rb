class CalendarController < ApplicationController
  def index
    @date = parse_date(params[:date])
    @tasks = Task.pending.parent_tasks
                 .where(due_date: @date.beginning_of_month.beginning_of_week..@date.end_of_month.end_of_week)
                 .order(:due_date)
    @start_date = @date.beginning_of_month.beginning_of_week
    @end_date = @date.end_of_month.end_of_week
  end

  def day
    @date = parse_date(params[:date])
    @tasks = Task.pending.parent_tasks
                 .where(due_date: @date.all_day)
                 .order(:due_date)
  end

  private

  def parse_date(date_param)
    date_param ? Date.parse(date_param) : Date.current
  rescue ArgumentError, TypeError
    Date.current
  end
end
