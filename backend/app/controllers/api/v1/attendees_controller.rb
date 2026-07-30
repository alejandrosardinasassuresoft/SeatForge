module Api
  module V1
    class AttendeesController < BaseController
      def registrations
        result = AttendeeRegistrationsQuery.new(params[:id]).call

        render json: {
          attendee: {
            id: result.attendee.id,
            name: result.attendee.name,
            email: result.attendee.email
          },
          registrations: result.registrations
        }
      end
    end
  end
end
