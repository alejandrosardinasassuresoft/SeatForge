module Sessions
  class Cancel
    Result = Struct.new(:session, :cancelled_counts, keyword_init: true)

    def self.call(...)
      new(...).call
    end

    def initialize(session_id:, cancellation_reason:, current_time: Time.current)
      @session_id = session_id
      @cancellation_reason = cancellation_reason.to_s.strip
      @current_time = current_time
    end

    def call
      if cancellation_reason.empty?
        raise Api::Errors::ValidationError.new(
          "Validation failed",
          details: ["Cancellation reason is required"],
          code: "validation_error"
        )
      end

      session = Session.find(session_id)
      cancelled_counts = { held: 0, confirmed: 0, waitlisted: 0 }

      Session.transaction do
        session.with_lock do
          session.reload

          if session.status == "cancelled"
            return Result.new(
              session: session,
              cancelled_counts: cancelled_counts
            )
          end

          held_regs = session.registrations.where(status: "held").to_a
          confirmed_regs = session.registrations.where(status: "confirmed").to_a
          waitlisted_regs = session.registrations.where(status: "waitlisted").to_a

          session.update!(
            status: "cancelled",
            cancelled_at: current_time,
            cancellation_reason: cancellation_reason
          )

          affected_regs = held_regs + confirmed_regs + waitlisted_regs
          affected_regs.each do |reg|
            reg.update!(
              status: "cancelled",
              cancelled_at: current_time,
              hold_expires_at: nil
            )
          end

          notify_regs = held_regs + confirmed_regs
          notify_regs.each do |reg|
            Registrations::SendNotificationJob.perform_later("session_cancelled", reg.id)
          end

          cancelled_counts = {
            held: held_regs.size,
            confirmed: confirmed_regs.size,
            waitlisted: waitlisted_regs.size
          }
        end
      end

      Result.new(
        session: session.reload,
        cancelled_counts: cancelled_counts
      )
    end

    private

    attr_reader :session_id, :cancellation_reason, :current_time
  end
end
