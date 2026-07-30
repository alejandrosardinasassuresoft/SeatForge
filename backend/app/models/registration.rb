class Registration < ApplicationRecord
  STATUSES = %w[held confirmed waitlisted cancelled expired].freeze
  ACTIVE_STATUSES = %w[held confirmed waitlisted].freeze

  belongs_to :attendee
  belongs_to :session

  validates :status, presence: true, inclusion: { in: STATUSES }
  validate :single_active_registration, if: :active_status?

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
