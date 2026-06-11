# frozen_string_literal: true

module Tasks
  class CompleteTask < ApplicationService
    def initialize(task_id)
      @task = Task.find(task_id)
    end

    def call
      ActiveRecord::Base.transaction do
        @task.update!(
          completed_at: Time.current,
          completed_count: @task.completed_count.to_i + 1
        )

        # Handle recurring tasks: recreate if recurring
        handle_recurring! if @task.is_recurring? && @task.recurring_interval.present?
      end

      Result.new(success: true, data: @task)
    rescue ActiveRecord::RecordNotFound => e
      Result.new(success: false, errors: ["Task not found: #{e.message}"])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def handle_recurring!
      interval = @task.recurring_interval
      next_date = case interval
                  when "daily" then @task.due_date + 1.day
                  when "weekly" then @task.due_date + 7.days
                  when "monthly" then @task.due_date + 1.month
                  else nil
                  end

      return unless next_date

      new_task = @task.dup
      new_task.assign_attributes(
        completed_at: nil,
        due_date: next_date,
        position: @task.column.tasks.maximum(:position).to_i + 1
      )
      new_task.save!

      # Copy tags
      @task.tags.each { |tag| new_task.tags << tag unless new_task.tags.include?(tag) }
    end
  end
end
