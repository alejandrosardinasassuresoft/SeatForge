module Api
  module V1
    class SessionsController < BaseController
      def index
        result = SessionSearchQuery.new(params).call

        render json: {
          sessions: result.sessions.map { |s| session_list_json(s) },
          pagination: result.pagination
        }
      end

      def show
        session = Session.includes(:workshop).find(params[:id])
        counts = session.registrations.group(:status).count

        render json: {
          id: session.id,
          starts_at: session.starts_at,
          ends_at: session.ends_at,
          capacity: session.capacity,
          status: session.status,
          workshop: {
            id: session.workshop.id,
            title: session.workshop.title,
            topic: session.workshop.topic,
            description: session.workshop.description
          },
          availability: {
            capacity: session.capacity,
            held_count: counts["held"].to_i,
            confirmed_count: counts["confirmed"].to_i,
            waitlist_count: counts["waitlisted"].to_i,
            available_seats: [session.capacity - counts["held"].to_i - counts["confirmed"].to_i, 0].max
          },
          created_at: session.created_at
        }
      end

      def create
        workshop = Workshop.find(params[:workshop_id])
        session = workshop.sessions.create!(session_params)

        render json: session, status: :created
      end

      private

      def session_params
        params.require(:session).permit(:starts_at, :ends_at, :capacity, :status)
      end

      def session_list_json(session)
        {
          id: session.id,
          starts_at: session.starts_at,
          ends_at: session.ends_at,
          capacity: session.capacity,
          status: session.status,
          workshop: {
            id: session.workshop.id,
            title: session.workshop.title,
            topic: session.workshop.topic
          }
        }
      end
    end
  end
end
