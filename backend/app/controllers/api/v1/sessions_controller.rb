module Api
  module V1
    class SessionsController < ApplicationController
      def create
        workshop = Workshop.find(params[:workshop_id])
        session = workshop.sessions.create!(session_params)

        render json: session, status: :created
      end

      private

      def session_params
        params.require(:session).permit(:starts_at, :ends_at, :capacity, :status)
      end
    end
  end
end
