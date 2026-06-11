# frozen_string_literal: true

module Subtasks
  class CompleteSubtask < ApplicationService
    def initialize(subtask_id)
      @subtask = Subtask.find(subtask_id)
    end

    def call
      @subtask.update!(completed_at: @subtask.completed_at? ? nil : Time.current)
      Result.new(success: true, data: @subtask)
    rescue ActiveRecord::RecordNotFound => e
      Result.new(success: false, errors: ["Subtask not found: #{e.message}"])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end
  end
end
