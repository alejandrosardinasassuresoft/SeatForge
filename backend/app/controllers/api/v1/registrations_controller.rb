module Api
  module V1
    class RegistrationsController < BaseController
      def create
        result = Registrations::Allocate.call(
          session_id: params[:session_id],
          attendee_params: attendee_params
        )

        render json: registration_json(result.registration), status: :created
      end

      def confirm
        result = Registrations::Transition.call(
          registration_id: params[:id],
          action: :confirm,
          current_time: Time.current
        )

        render json: registration_json(result.registration)
      end

      def cancel
        result = Registrations::Transition.call(
          registration_id: params[:id],
          action: :cancel,
          current_time: Time.current
        )

        render json: registration_json(result.registration)
      end

      private

      def attendee_params
        params.require(:attendee).permit(:name, :email)
      end

      def registration_json(registration)
        {
          id: registration.id,
          status: registration.status,
          session_id: registration.session_id,
          attendee: {
            id: registration.attendee.id,
            name: registration.attendee.name,
            email: registration.attendee.email
          },
          hold_expires_at: registration.hold_expires_at,
          confirmed_at: registration.confirmed_at,
          cancelled_at: registration.cancelled_at,
          created_at: registration.created_at
        }
      end
    end
  end
end