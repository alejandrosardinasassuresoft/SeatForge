module Registrations
  class Allocate
    HOLD_DURATION = 10.minutes
    Result = Struct.new(:registration, :attendee, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(session_id:, attendee_params:, current_time: Time.current)
      @session_id = session_id
      @attendee_params = attendee_params.to_h.symbolize_keys
      @current_time = current_time
    end

    def call
      session = Session.find(session_id)
      validate_attendee_identity!
      attendee = find_or_create_attendee!

      registration = Session.transaction do
        session.with_lock do
          session.reload
          ensure_session_available!(session)
          ensure_no_duplicate_registration!(attendee, session)
          ensure_no_overlapping_registration!(attendee, session)
          create_registration!(attendee, session)
        end
      end

      Result.new(registration: registration, attendee: attendee)
    rescue ActiveRecord::RecordNotUnique
      raise duplicate_registration_error
    end

    private

    attr_reader :session_id, :attendee_params, :current_time

    def validate_attendee_identity!
      attendee = Attendee.new(name: attendee_params[:name], email: normalized_email)
      attendee.errors.add(:name, :blank) if attendee.name.blank?
      attendee.errors.add(:email, :blank) if attendee.email.blank?

      raise ActiveRecord::RecordInvalid.new(attendee) if attendee.errors.any?
    end

    def find_or_create_attendee!
      Attendee.find_by(email: normalized_email) || Attendee.create!(email: normalized_email, name: attendee_params[:name])
    rescue ActiveRecord::RecordNotUnique
      Attendee.find_by!(email: normalized_email)
    end

    def normalized_email
      @normalized_email ||= attendee_params[:email].to_s.strip.downcase.presence
    end

    def ensure_session_available!(session)
      return if session.registration_open?(current_time)

      raise Api::Errors::ConflictError.new(
        "Session is not available for registration",
        details: ["Session is cancelled, completed, or already started"],
        code: "registration_unavailable"
      )
    end

    def ensure_no_duplicate_registration!(attendee, session)
      return unless Registration.exists?(
        attendee_id: attendee.id,
        session_id: session.id,
        status: Registration::ACTIVE_STATUSES
      )

      raise duplicate_registration_error
    end

    def ensure_no_overlapping_registration!(attendee, session)
      overlap_exists = Registration
        .where(attendee_id: attendee.id)
        .active_for_schedule_conflicts
        .overlapping_session_window(session)
        .exists?

      return unless overlap_exists

      raise Api::Errors::ConflictError.new(
        "Attendee already has an active registration for an overlapping session",
        details: ["Held or confirmed registrations cannot overlap in time"],
        code: "registration_schedule_conflict"
      )
    end

    def create_registration!(attendee, session)
      if SessionAvailabilityQuery.call(session: session, current_time: current_time).available_seats.positive?
        Registration.create!(
          attendee: attendee,
          session: session,
          status: "held",
          hold_expires_at: (current_time + HOLD_DURATION).utc
        )
      else
        Registration.create!(
          attendee: attendee,
          session: session,
          status: "waitlisted"
        )
      end
    end

    def duplicate_registration_error
      Api::Errors::ConflictError.new(
        "Attendee already has an active registration for this session",
        details: ["Only one active registration is allowed per attendee and session"],
        code: "duplicate_registration"
      )
    end
  end
end
