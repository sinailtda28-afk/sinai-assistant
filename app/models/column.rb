class Column < ApplicationRecord
  has_many :tasks, -> { order(position: :asc) }, dependent: :destroy
  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
  scope :ordered, -> { order(position: :asc) }
end
