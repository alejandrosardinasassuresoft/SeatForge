module Registrations
  class ExpireHoldsJob < ActiveJob::Base
    queue_as :default

    HOLD_DURATION = 10.minutes

    def perform(current_time = Time.current)
      current_time = Time.zone.parse(current_time.to_s) if current_time.is_a?(String)

      expired_registrations = Registration.where(status: "held")
                                           .where("hold_expires_at <= ?", current_time)

      expired_registrations.find_each do |registration|
        session = registration.session
        session.with_lock do
          registration.reload
          next unless registration.status == "held" && registration.hold_expires_at.present? && registration.hold_expires_at <= current_time

          registration.update!(status: "expired")
          promote_oldest_waitlist_entry(session, current_time)
        end
      end
    end

    private

    def promote_oldest_waitlist_entry(session, current_time)
      return unless session.available_seats.positive?

      oldest_waitlist = session.registrations.eligible_waitlist_order.first
      return unless oldest_waitlist

      oldest_waitlist.update!(
        status: "held",
        hold_expires_at: (current_time + HOLD_DURATION).utc
      )

      SendNotificationJob.perform_later("promoted", oldest_waitlist.id)
    end
  end
end
