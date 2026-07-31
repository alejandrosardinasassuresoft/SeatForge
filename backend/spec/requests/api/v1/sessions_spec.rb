require "rails_helper"

RSpec.describe "Api::V1::Sessions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:workshop) { create(:workshop, topic: "rails", title: "Rails Deep Dive") }

  around do |example|
    travel_to(current_time) { example.run }
  end

  before do
    create(:session, workshop: workshop, capacity: 3,
      starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
    create(:session, workshop: workshop, capacity: 2,
      starts_at: current_time + 2.days, ends_at: current_time + 2.days + 2.hours)
  end

  describe "GET /api/v1/sessions" do
    it "returns sessions with HTTP 200" do
      get "/api/v1/sessions"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["sessions"].size).to eq(2)
      expect(json["pagination"]).to include("current_page", "per_page", "total_records", "total_pages")
    end

    it "includes workshop info in each session" do
      get "/api/v1/sessions"

      json = response.parsed_body
      json["sessions"].each do |s|
        expect(s["workshop"]).to include("id", "title", "topic")
      end
    end

    it "filters by topic" do
      other = create(:workshop, topic: "vue")
      create(:session, workshop: other, starts_at: current_time + 3.days, ends_at: current_time + 3.days + 2.hours)

      get "/api/v1/sessions", params: { topic: "rails" }

      json = response.parsed_body
      expect(json["sessions"].size).to eq(2)
    end

    it "filters by available seats" do
      full = Session.find_by(capacity: 2)
      create(:registration, session: full, status: "held")
      create(:registration, session: full, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)

      get "/api/v1/sessions", params: { available: "true" }

      json = response.parsed_body
      expect(json["sessions"].size).to eq(1)
    end

    it "paginates results" do
      get "/api/v1/sessions", params: { page: 1, per_page: 1 }

      json = response.parsed_body
      expect(json["sessions"].size).to eq(1)
      expect(json["pagination"]["current_page"]).to eq(1)
      expect(json["pagination"]["per_page"]).to eq(1)
      expect(json["pagination"]["total_records"]).to eq(2)
    end

    it "sorts by capacity descending" do
      get "/api/v1/sessions", params: { sort: "capacity", order: "desc" }

      json = response.parsed_body
      capacities = json["sessions"].map { |s| s["capacity"] }
      expect(capacities).to eq(capacities.sort.reverse)
    end
  end

  describe "GET /api/v1/sessions/:id" do
    it "returns session details with availability" do
      session = Session.order(:starts_at).first

      get "/api/v1/sessions/#{session.id}"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["id"]).to eq(session.id)
      expect(json["workshop"]).to include("id", "title", "topic", "description")
      expect(json["availability"]).to include("capacity", "held_count", "confirmed_count", "waitlist_count", "available_seats")
    end

    it "returns availability with accurate counts" do
      session = Session.order(:starts_at).first
      create(:registration, session: session, status: "held")
      create(:registration, session: session, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)

      get "/api/v1/sessions/#{session.id}"

      json = response.parsed_body
      expect(json["availability"]["held_count"]).to eq(1)
      expect(json["availability"]["confirmed_count"]).to eq(1)
      expect(json["availability"]["available_seats"]).to eq(session.capacity - 2)
    end

    it "returns 404 for missing session" do
      get "/api/v1/sessions/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]["code"]).to eq("not_found")
    end
  end
  describe "POST /api/v1/sessions/:id/cancel" do
    let(:session_to_cancel) do
      create(:session, workshop: workshop, starts_at: current_time + 3.days, ends_at: current_time + 3.days + 2.hours)
    end
    let(:valid_params) { { cancellation_reason: "Instructor unavailable" } }

    it "cancels a session and returns prior-status registration counts" do
      create(:registration, session: session_to_cancel, status: "held")
      create(:registration, session: session_to_cancel, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)
      create(:registration, session: session_to_cancel, status: "waitlisted", hold_expires_at: nil)
      create(:registration, session: session_to_cancel, status: "expired", hold_expires_at: current_time - 1.minute)
      create(:registration, session: session_to_cancel, status: "cancelled", cancelled_at: current_time - 1.day)

      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: valid_params

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["session"]).to include(
        "id" => session_to_cancel.id,
        "status" => "cancelled",
        "cancellation_reason" => "Instructor unavailable"
      )
      expect(json["session"]["cancelled_at"]).to be_present
      expect(json["cancelled_registrations"]).to eq("held" => 1, "confirmed" => 1, "waitlisted" => 1)
      expect(json["cancelled_count"]).to eq(3)
    end

    it "returns validation_error when cancellation reason is missing" do
      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("code" => "validation_error")
    end

    it "returns validation_error when cancellation reason is blank" do
      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: { cancellation_reason: "   " }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("code" => "validation_error")
    end

    it "returns not_found for missing sessions" do
      post "/api/v1/sessions/999999/cancel", params: valid_params

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to include("code" => "not_found")
    end

    it "returns a conflict envelope for sessions that cannot be cancelled" do
      session_to_cancel.update!(status: "completed")

      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: valid_params

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to include("code" => "session_cancellation_unavailable")
    end

    it "is idempotent for repeated cancellation requests" do
      create(:registration, session: session_to_cancel, status: "held")

      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: valid_params
      first_cancelled_at = response.parsed_body["session"]["cancelled_at"]

      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: { cancellation_reason: "Retry reason" }

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["session"]["cancellation_reason"]).to eq("Instructor unavailable")
      expect(json["session"]["cancelled_at"]).to eq(first_cancelled_at)
      expect(json["cancelled_registrations"]).to eq("held" => 0, "confirmed" => 0, "waitlisted" => 0)
      expect(json["cancelled_count"]).to eq(0)
    end

    it "rejects new registrations after cancellation" do
      post "/api/v1/sessions/#{session_to_cancel.id}/cancel", params: valid_params

      post "/api/v1/sessions/#{session_to_cancel.id}/registrations", params: {
        attendee: {
          name: "Alejandro Sardinas",
          email: "alejandro@example.com"
        }
      }

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to include("code" => "registration_unavailable")
    end
  end
end
