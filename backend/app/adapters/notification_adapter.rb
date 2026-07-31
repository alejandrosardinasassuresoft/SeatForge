class NotificationAdapter
  class LoggerAdapter
    def self.notify(event_type:, registration_id:)
      registration = Registration.find_by(id: registration_id)
      return unless registration

      attendee = registration.attendee
      session = registration.session
      workshop = session&.workshop

      Rails.logger.info "[NOTIFICATION] Event: #{event_type.to_s.upcase} | To: #{attendee&.name} <#{attendee&.email}> | Workshop: '#{workshop&.title}' | Registration Status: #{registration.status}"
      { event_type: event_type, registration_id: registration_id }
    end
  end

  class << self
    attr_writer :adapter

    def adapter
      @adapter ||= LoggerAdapter
    end

    def notify(event_type:, registration_id:)
      adapter.notify(event_type: event_type, registration_id: registration_id)
    end

    def reset!
      @adapter = LoggerAdapter
    end
  end
end
