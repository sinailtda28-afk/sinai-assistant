# frozen_string_literal: true

class HistoryController < ApplicationController
  def index
    @tasks = Task.completed
                 .includes(:column, :tags)
                 .order(completed_at: :desc)
                 .limit(50)
    @total = Task.completed.count
  end
end
