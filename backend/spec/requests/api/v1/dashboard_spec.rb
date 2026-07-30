require "rails_helper"

RSpec.describe "Api::V1::Dashboard", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:workshop) { create(:workshop) }

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe "GET /api/v1/dashboard" do
    it "returns all required metrics with HTTP 200" do
      get "/api/v1/dashboard"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json).to include(
        "upcoming_scheduled_sessions",
        "total_held",
        "total_confirmed",
        "total_waitlisted",
        "expired_holds_today",
        "full_sessions",
        "top_waitlisted_sessions"
      )
    end

    it "returns accurate counts" do
      s1 = create(:session, workshop: workshop,
        starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours, capacity: 1)
      s2 = create(:session, workshop: workshop,
        starts_at: current_time + 2.days, ends_at: current_time + 2.days + 2.hours, capacity: 3)

      create(:registration, session: s1, status: "held")
      create(:registration, session: s2, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)
      create(:registration, session: s2, status: "waitlisted")
      create(:registration, session: s2, status: "waitlisted")

      get "/api/v1/dashboard"

      json = response.parsed_body
      expect(json["upcoming_scheduled_sessions"]).to eq(2)
      expect(json["total_held"]).to eq(1)
      expect(json["total_confirmed"]).to eq(1)
      expect(json["total_waitlisted"]).to eq(2)
    end

    it "identifies full sessions" do
      s1 = create(:session, workshop: workshop, capacity: 1,
        starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
      create(:registration, session: s1, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)

      get "/api/v1/dashboard"

      json = response.parsed_body
      expect(json["full_sessions"]).not_to be_empty
      expect(json["full_sessions"].first["id"]).to eq(s1.id)
    end

    it "returns top waitlisted sessions" do
      s1 = create(:session, workshop: workshop,
        starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours, capacity: 1)
      create(:registration, session: s1, status: "waitlisted")
      create(:registration, session: s1, status: "waitlisted")

      get "/api/v1/dashboard"

      json = response.parsed_body
      expect(json["top_waitlisted_sessions"]).not_to be_empty
      expect(json["top_waitlisted_sessions"].first["waitlist_size"]).to eq(2)
    end

    it "handles empty data gracefully" do
      Registration.delete_all
      Session.delete_all

      get "/api/v1/dashboard"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["upcoming_scheduled_sessions"]).to eq(0)
      expect(json["full_sessions"]).to be_empty
      expect(json["top_waitlisted_sessions"]).to be_empty
    end
  end
end
