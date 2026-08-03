class Registration < ApplicationRecord
  STATUSES = %w[held confirmed waitlisted cancelled expired].freeze
  ACTIVE_STATUSES = %w[held confirmed waitlisted].freeze
  CAPACITY_CONSUMING_STATUSES = %w[held confirmed].freeze
  SCHEDULE_CONFLICT_STATUSES = %w[held confirmed].freeze

  belongs_to :attendee
  belongs_to :session

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :single_active_registration, if: :active_status?

  scope :active_capacity_consumers, lambda { |at_time = Time.current|
    where(
      "status = :confirmed OR (status = :held AND hold_expires_at > :at_time)",
      confirmed: "confirmed",
      held: "held",
      at_time: at_time
    )
  }
  scope :active_for_schedule_conflicts, -> { where(status: SCHEDULE_CONFLICT_STATUSES) }
  scope :overlapping_session_window, lambda { |session|
    joins(:session)
      .where.not(session_id: session.id)
      .where("sessions.starts_at < ? AND sessions.ends_at > ?", session.ends_at, session.starts_at)
  }
  scope :eligible_waitlist_order, -> { where(status: "waitlisted").order(:created_at, :id) }
  scope :expired_holds, ->(at_time = Time.current) { where(status: "held").where("hold_expires_at IS NOT NULL AND hold_expires_at <= ?", at_time) }

  def active_status?
    ACTIVE_STATUSES.include?(status)
  end

  private

  def single_active_registration
    return if attendee_id.blank? || session_id.blank?

    duplicate = self.class
      .where(attendee_id: attendee_id, session_id: session_id, status: ACTIVE_STATUSES)
      .where.not(id: id)
      .exists?

    errors.add(:base, "attendee already has an active registration for this session") if duplicate
  end
end
