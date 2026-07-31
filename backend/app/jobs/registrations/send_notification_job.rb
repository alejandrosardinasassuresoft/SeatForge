module Registrations
  class SendNotificationJob < ActiveJob::Base
    queue_as :default

    def perform(event_type, registration_id)
      NotificationAdapter.notify(event_type: event_type, registration_id: registration_id)
    end
  end
end
