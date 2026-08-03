require "rails_helper"

RSpec.describe "Api::V1::Registrations transitions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:session_record) do
    create(
      :session,
      capacity: 1,
      starts_at: current_time + 1.day,
      ends_at: current_time + 1.day + 2.hours
    )
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  describe "POST /api/v1/registrations/:id/confirm" do
    it "confirms a held registration" do
      registration = create(:registration, session: session_record, status: "held", hold_expires_at: current_time + 10.minutes)

      post "/api/v1/registrations/#{registration.id}/confirm"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["status"]).to eq("confirmed")
    end

    it "returns hold_expired in the validation envelope at the expiration boundary" do
      registration = create(:registration, session: session_record, status: "held", hold_expires_at: current_time)

      post "/api/v1/registrations/#{registration.id}/confirm"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.fetch("error")).to include(
        "code" => "hold_expired",
        "message" => "Registration hold expired before confirmation"
      )
      expect(registration.reload.status).to eq("held")
    end

    it "returns a conflict envelope for a waitlisted registration" do
      registration = create(:registration, session: session_record, status: "waitlisted", hold_expires_at: nil)

      post "/api/v1/registrations/#{registration.id}/confirm"

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body.dig("error", "code")).to eq("registration_conflict")
      expect(registration.reload.status).to eq("waitlisted")
    end
  end

  describe "POST /api/v1/registrations/:id/cancel" do
    it "cancels a registration and promotes a waitlisted one" do
      registration = create(:registration, session: session_record, status: "held", hold_expires_at: current_time + 10.minutes)
      waitlisted = create(:registration, session: session_record, status: "waitlisted", hold_expires_at: nil, created_at: 2.hours.ago)

      post "/api/v1/registrations/#{registration.id}/cancel"

      expect(response).to have_http_status(:ok)
      expect(registration.reload.status).to eq("cancelled")
      expect(waitlisted.reload.status).to eq("held")
    end
  end
end
