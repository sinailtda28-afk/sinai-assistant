# frozen_string_literal: true

module Tasks
  # Moves a task to a different column and/or position.
  # Re-indexes positions within the destination column.
  class MoveTask < ApplicationService
    def initialize(task_id, column_id, position = nil)
      @task = Task.find(task_id)
      @new_column = Column.find(column_id)
      @new_position = position
    end

    def call
      ActiveRecord::Base.transaction do
        @task.update!(column_id: @new_column.id)

        if @new_position
          @task.update!(position: @new_position)
          reindex_positions!
        end
      end

      Result.new(success: true, data: @task)
    rescue ActiveRecord::RecordNotFound => e
      Result.new(success: false, errors: ["Not found: #{e.message}"])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def reindex_positions!
      @new_column.tasks.order(:position, :id).each_with_index do |t, i|
        t.update_column(:position, i)
      end
    end
  end
end
