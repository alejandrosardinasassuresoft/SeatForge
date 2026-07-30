require "rails_helper"

RSpec.describe "Api::V1::Registrations", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:session_record) do
    create(:session, capacity: 2, starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
  end
  let(:valid_params) do
    {
      attendee: {
        name: "Alejandro Sardinas",
        email: "alejandro@example.com"
      }
    }
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe "POST /api/v1/sessions/:session_id/registrations" do
    it "returns a held registration when capacity remains" do
      post "/api/v1/sessions/#{session_record.id}/registrations", params: valid_params

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["status"]).to eq("held")
      expect(json["session_id"]).to eq(session_record.id)
      expect(json["hold_expires_at"]).to be_present
      expect(json["attendee"]).to include(
        "name" => "Alejandro Sardinas",
        "email" => "alejandro@example.com"
      )
    end

    it "returns a waitlisted registration when capacity is full" do
      create(:registration, session: session_record, status: "held")
      create(:registration, session: session_record, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)

      post "/api/v1/sessions/#{session_record.id}/registrations", params: valid_params

      expect(response).to have_http_status(:created)
      json = response.parsed_body
      expect(json["status"]).to eq("waitlisted")
      expect(json["hold_expires_at"]).to be_nil
    end

    it "returns validation_error for invalid attendee input" do
      post "/api/v1/sessions/#{session_record.id}/registrations", params: { attendee: { name: "", email: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("code" => "validation_error")
    end

    it "returns validation_error for missing attendee input" do
      post "/api/v1/sessions/#{session_record.id}/registrations", params: {}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body["error"]).to include("code" => "validation_error")
    end

    it "returns not_found for missing sessions" do
      post "/api/v1/sessions/999999/registrations", params: valid_params

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]).to include("code" => "not_found")
    end

    it "returns registration_unavailable for unavailable sessions" do
      session_record.update!(status: "cancelled")

      post "/api/v1/sessions/#{session_record.id}/registrations", params: valid_params

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to include("code" => "registration_unavailable")
    end

    it "returns duplicate_registration for duplicate active registrations" do
      attendee = create(:attendee, email: "alejandro@example.com")
      create(:registration, attendee: attendee, session: session_record, status: "held")

      post "/api/v1/sessions/#{session_record.id}/registrations", params: valid_params

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to include("code" => "duplicate_registration")
    end

    it "returns registration_schedule_conflict for overlapping active registrations" do
      attendee = create(:attendee, email: "alejandro@example.com")
      overlapping_session = create(
        :session,
        starts_at: session_record.starts_at + 30.minutes,
        ends_at: session_record.ends_at + 30.minutes
      )
      create(:registration, attendee: attendee, session: overlapping_session, status: "confirmed", hold_expires_at: nil)

      post "/api/v1/sessions/#{session_record.id}/registrations", params: valid_params

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body["error"]).to include("code" => "registration_schedule_conflict")
    end
  end
end