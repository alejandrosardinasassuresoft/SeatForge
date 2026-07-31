module Registrations
  class Transition
    HOLD_DURATION = 10.minutes
    Result = Struct.new(:registration, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(registration_id:, action:, current_time: Time.current)
      @registration_id = registration_id
      @action = action.to_s
      @current_time = current_time
    end

    def call
      registration = Registration.find(registration_id)

      Registration.transaction do
        registration.with_lock do
          registration.reload
          case action
          when "confirm"
            confirm!(registration)
          when "cancel"
            cancel!(registration)
          when "promote"
            promote!(registration)
          else
            raise Api::Errors::ConflictError.new(
              "Invalid registration action",
              details: ["Action must be one of confirm, cancel, or promote"],
              code: "registration_conflict"
            )
          end
        end
      end

      Result.new(registration: registration.reload)
    end

    private

    attr_reader :registration_id, :action, :current_time

    def confirm!(registration)
      return registration if registration.status == "confirmed"

      if registration.status == "held" && registration.hold_expires_at.present? && registration.hold_expires_at <= current_time
        raise Api::Errors::ConflictError.new(
          "Registration hold expired before confirmation",
          details: ["The hold window has expired"],
          code: "hold_expired"
        )
      end

      registration.update!(
        status: "confirmed",
        confirmed_at: current_time,
        hold_expires_at: nil,
        cancelled_at: nil
      )

      SendNotificationJob.perform_later("confirmed", registration.id)
      registration
    end

    def cancel!(registration)
      return registration if registration.status == "cancelled"

      registration.update!(
        status: "cancelled",
        cancelled_at: current_time,
        hold_expires_at: nil
      )

      promote_waitlisted_registration!(registration.session)
      registration
    end

    def promote!(registration)
      return registration if registration.status == "held" || registration.status == "confirmed"
      return registration unless registration.status == "waitlisted"

      registration.update!(
        status: "held",
        hold_expires_at: (current_time + HOLD_DURATION).utc,
        confirmed_at: nil,
        cancelled_at: nil
      )

      SendNotificationJob.perform_later("promoted", registration.id)
      registration
    end

    def promote_waitlisted_registration!(session)
      return if session.nil?
      return unless session.available_seats.positive?

      waitlisted_registration = session.registrations.eligible_waitlist_order.first
      return if waitlisted_registration.blank?

      waitlisted_registration.update!(
        status: "held",
        hold_expires_at: (current_time + HOLD_DURATION).utc,
        confirmed_at: nil,
        cancelled_at: nil
      )

      SendNotificationJob.perform_later("promoted", waitlisted_registration.id)
    end
  end
end
