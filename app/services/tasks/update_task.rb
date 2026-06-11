# frozen_string_literal: true

module Tasks
  # Updates an existing task with the given attributes.
  # Handles column changes, tag resolution, and position updates.
  class UpdateTask < ApplicationService
    def initialize(task_id, params)
      @task = Task.find(task_id)
      @params = params.dup
      @tags = Array(@params.delete(:tags))
    end

    def call
      ActiveRecord::Base.transaction do
        handle_column_change if @params.key?(:column_id)
        @task.update!(@params)
        resolve_tags! if @tags.any?
      end

      Result.new(success: true, data: @task)
    rescue ActiveRecord::RecordNotFound => e
      Result.new(success: false, errors: ["Task not found: #{e.message}"])
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def handle_column_change
      new_column = Column.find(@params.delete(:column_id))
      @task.position = new_column.tasks.maximum(:position).to_i + 1
      @task.column = new_column
    end

    def resolve_tags!
      @task.task_tags.destroy_all
      @tags.each do |tag_name|
        tag = Tag.find_or_create_by!(name: tag_name.strip.downcase)
        @task.tags << tag
      end
    end
  end
end
