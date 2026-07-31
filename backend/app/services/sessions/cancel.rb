module Sessions
  class Cancel
    CANCELLABLE_REGISTRATION_STATUSES = %w[held confirmed waitlisted].freeze

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
      session = Session.find(session_id)

      Session.transaction do
        session.with_lock do
          session.reload
          if session.status == "cancelled"
            idempotent_result(session)
          else
            ensure_cancellable!(session)
            cancel_session!(session)
            cancelled_counts = cancel_registrations!(session)

            Result.new(session: session.reload, cancelled_counts: cancelled_counts)
          end
        end
      end
    end

    private

    attr_reader :session_id, :cancellation_reason, :current_time

    def idempotent_result(session)
      Result.new(session: session, cancelled_counts: zero_counts)
    end

    def ensure_cancellable!(session)
      return if session.status == "scheduled" && session.starts_at.present? && session.starts_at > current_time

      raise Api::Errors::ConflictError.new(
        "Session cannot be cancelled",
        details: ["Only scheduled sessions that have not started can be cancelled"],
        code: "session_cancellation_unavailable"
      )
    end

    def cancel_session!(session)
      session.update!(
        status: "cancelled",
        cancellation_reason: cancellation_reason,
        cancelled_at: current_time.utc
      )
    end

    def cancel_registrations!(session)
      scope = session.registrations.where(status: CANCELLABLE_REGISTRATION_STATUSES)
      counts = zero_counts.merge(scope.group(:status).count.transform_keys(&:to_s))

      scope.update_all(
        status: "cancelled",
        cancelled_at: current_time.utc,
        hold_expires_at: nil,
        updated_at: current_time.utc
      )

      counts
    end

    def zero_counts
      CANCELLABLE_REGISTRATION_STATUSES.index_with(0)
    end
  end
end