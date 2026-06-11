# frozen_string_literal: true

module Tasks
  # Creates a new task with the given attributes.
  # Automatically assigns to the first column if none specified.
  # Handles tag resolution (finds existing or creates new tags).
  class CreateTask < ApplicationService
    def initialize(params)
      @params = params.dup
      @column = find_or_default_column(@params.delete(:column_id))
      @tags = Array(@params.delete(:tags))
    end

    def call
      task = @column.tasks.build(@params)
      task.position = @column.tasks.maximum(:position).to_i + 1

      ActiveRecord::Base.transaction do
        task.save!
        resolve_tags!(task)
      end

      Result.new(success: true, data: task)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, errors: [e.message])
    end

    private

    def find_or_default_column(column_id)
      column_id ? Column.find(column_id) : Column.order(:position).first!
    end

    def resolve_tags!(task)
      @tags.each do |tag_name|
        tag = Tag.find_or_create_by!(name: tag_name.strip.downcase)
        task.tags << tag unless task.tags.include?(tag)
      end
    end
  end
end
