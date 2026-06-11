# frozen_string_literal: true

module Subtasks
  class CreateSubtask < ApplicationService
    def initialize(parent_task_id, params)
      @parent = Task.find(parent_task_id)
      @params = params
    end

    def call
      subtask = @parent.subtasks.build(@params)
      subtask.column = @parent.column
      subtask.position = @parent.subtasks.maximum(:position).to_i + 1
      subtask.save!

      Result.new(success: true, data: subtask)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end
  end
end
