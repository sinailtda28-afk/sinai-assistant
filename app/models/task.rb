class Task < ApplicationRecord
  belongs_to :column
  belongs_to :parent_task, class_name: "Task", optional: true
  has_many :subtasks, class_name: "Task", foreign_key: :parent_task_id, dependent: :destroy
  has_many :task_tags, dependent: :destroy
  has_many :tags, through: :task_tags
  has_many_attached :files
  has_many :comments, dependent: :destroy

  validates :title, presence: true

  enum :priority, { low: 0, medium: 1, high: 2 }

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :parent_tasks, -> { where(parent_task_id: nil) }
  scope :subtasks, -> { where.not(parent_task_id: nil) }
  scope :recurring, -> { where(is_recurring: true) }
  scope :due_today, -> { where(due_date: Date.current.all_day) }
  scope :overdue, -> { pending.where("due_date < ?", Time.current) }
  scope :by_priority, -> { order(priority: :desc) }

  # Filter scopes
  scope :by_priority_filter, ->(priority) { where(priority: priority) if priority.present? }
  scope :by_tag, ->(tag_name) {
    if tag_name.present?
      joins(:tags).where(tags: { name: tag_name })
    end
  }
  scope :due_in_range, ->(start_date, end_date) {
    if start_date.present? && end_date.present?
      where(due_date: start_date.to_date.beginning_of_day..end_date.to_date.end_of_day)
    elsif start_date.present?
      where("due_date >= ?", start_date.to_date.beginning_of_day)
    elsif end_date.present?
      where("due_date <= ?", end_date.to_date.end_of_day)
    end
  }

  def subtasks?
    subtasks.any?
  end

  def completed_subtasks?
    subtasks.completed.count == subtasks.count
  end
end
