require "swagger_helper"

RSpec.describe "API V1 Attendees", type: :request do
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

  path "/api/v1/attendees/{id}/registrations" do
    get("list attendee registrations") do
      tags "Attendees"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer, required: true,
                description: "Attendee ID"

      response "200", "attendee registrations list" do
        let(:id) { attendee.id }

        schema "$ref" => "#/components/schemas/attendee_registrations"

        before do
          create(:registration, attendee: attendee, session: session, status: "confirmed",
            hold_expires_at: nil, confirmed_at: current_time)
        end

        run_test! do |response|
          json = response.parsed_body
          expect(json["attendee"]["name"]).to eq("Sam Wilson")
          expect(json["registrations"]).to be_present
        end
      end

      response "404", "attendee not found" do
        let(:id) { 999999 }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end
end
