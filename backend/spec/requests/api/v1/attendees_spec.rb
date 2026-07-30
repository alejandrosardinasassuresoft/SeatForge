require "rails_helper"

RSpec.describe "Api::V1::Attendees", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:attendee) { create(:attendee, name: "Sam Wilson", email: "sam@example.com") }
  let(:workshop) { create(:workshop, title: "API Design") }
  let(:session) do
    create(:session, workshop: workshop,
      starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe "GET /api/v1/attendees/:id/registrations" do
    it "returns registrations with HTTP 200" do
      create(:registration, attendee: attendee, session: session, status: "confirmed",
        hold_expires_at: nil, confirmed_at: current_time)

      get "/api/v1/attendees/#{attendee.id}/registrations"

      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json["attendee"]["name"]).to eq("Sam Wilson")
      expect(json["registrations"].size).to eq(1)
    end

    it "includes session and workshop info" do
      create(:registration, attendee: attendee, session: session, status: "held")

      get "/api/v1/attendees/#{attendee.id}/registrations"

      json = response.parsed_body
      reg = json["registrations"].first
      expect(reg["session"]).to include("id", "starts_at", "ends_at", "workshop_title")
      expect(reg["session"]["workshop_title"]).to eq("API Design")
    end

    it "returns empty list when attendee has no registrations" do
      get "/api/v1/attendees/#{attendee.id}/registrations"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["registrations"]).to be_empty
    end

    it "returns 404 for missing attendee" do
      get "/api/v1/attendees/999999/registrations"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]["code"]).to eq("not_found")
    end
  end
end
