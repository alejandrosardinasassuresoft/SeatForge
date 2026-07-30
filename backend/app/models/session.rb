class Session < ApplicationRecord
  STATUSES = %w[scheduled cancelled completed].freeze

  belongs_to :workshop
  has_many :registrations, dependent: :restrict_with_error

  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validates :starts_at, presence: true
  validates :ends_at, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :ends_after_starts_at

  def capacity_consumers_count
    registrations.active_capacity_consumers.count
  end

  def available_seats
    [capacity - capacity_consumers_count, 0].max
  end

  def waitlist_count
    registrations.where(status: "waitlisted").count
  end

  private

  def ends_after_starts_at
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "must be after starts at")
  end
end
