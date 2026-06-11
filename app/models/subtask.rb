class Subtask < ApplicationRecord
  belongs_to :task

  validates :title, presence: true

  scope :completed, -> { where.not(completed_at: nil) }
  scope :pending, -> { where(completed_at: nil) }
  scope :ordered, -> { order(position: :asc) }
end
