# frozen_string_literal: true

module Tasks
  class RecurringTask < ApplicationService
    def initialize(completed_task)
      @original = completed_task
    end

    def call
      next_due = calculate_next_due
      first_column = Column.order(:position).first!

      new_task = first_column.tasks.build(
        title: @original.title,
        description: @original.description,
        priority: @original.priority,
        due_date: next_due,
        position: first_column.tasks.maximum(:position).to_i + 1,
        parent_task_id: @original.parent_task_id || @original.id
      )
      new_task.save!

      @original.tags.each do |tag|
        new_task.tags << tag unless new_task.tags.include?(tag)
      end

      Result.new(success: true, data: new_task)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def calculate_next_due
      base = @original.due_date || Time.current
      case @original.recurrence_type
      when "daily"
        base + 1.day
      when "weekly"
        if @original.recurrence_day
          days_to_add = (@original.recurrence_day - base.wday) % 7
          days_to_add = 7 if days_to_add == 0
          base + days_to_add.days
        else
          base + 7.days
        end
      when "monthly"
        base + 1.month
      end
    end
  end
end
