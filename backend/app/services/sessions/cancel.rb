module Sessions
  class Cancel
    CANCELLABLE_REGISTRATION_STATUSES = %w[held confirmed waitlisted].freeze
    NOTIFIABLE_REGISTRATION_STATUSES = %w[held confirmed].freeze

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
      ensure_cancellation_reason!

      session = Session.find(session_id)

      Session.transaction do
        session.with_lock do
          session.reload
          if session.status == "cancelled"
            idempotent_result(session)
          else
            ensure_cancellable!(session)
            registration_groups = registrations_by_status(session)

            cancel_session!(session)
            cancel_registrations!(registration_groups.values.flatten)
            enqueue_notifications!(registration_groups)

            Result.new(session: session.reload, cancelled_counts: counts_for(registration_groups))
          end
        end
      end
    end

    private

    attr_reader :session_id, :cancellation_reason, :current_time

    def ensure_cancellation_reason!
      return if cancellation_reason.present?

      raise Api::Errors::ValidationError.new(
        "Validation failed",
        details: ["Cancellation reason is required"],
        code: "validation_error"
      )
    end

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

    def registrations_by_status(session)
      CANCELLABLE_REGISTRATION_STATUSES.index_with do |status|
        session.registrations.where(status: status).to_a
      end
    end

    def cancel_session!(session)
      session.update!(
        status: "cancelled",
        cancellation_reason: cancellation_reason,
        cancelled_at: current_time.utc
      )
    end

    def cancel_registrations!(registrations)
      registrations.each do |registration|
        registration.update!(
          status: "cancelled",
          cancelled_at: current_time.utc,
          hold_expires_at: nil
        )
      end
    end

    def enqueue_notifications!(registration_groups)
      NOTIFIABLE_REGISTRATION_STATUSES.each do |status|
        registration_groups.fetch(status).each do |registration|
          Registrations::SendNotificationJob.perform_later("session_cancelled", registration.id)
        end
      end
    end

    def counts_for(registration_groups)
      CANCELLABLE_REGISTRATION_STATUSES.index_with { |status| registration_groups.fetch(status).size }
    end

    def zero_counts
      CANCELLABLE_REGISTRATION_STATUSES.index_with(0)
    end
  end
end