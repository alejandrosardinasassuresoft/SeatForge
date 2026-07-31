require "swagger_helper"

RSpec.describe "API V1 Dashboard", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }

  around do |example|
    travel_to(current_time) { example.run }
  end

  path "/api/v1/dashboard" do
    get("show dashboard metrics") do
      tags "Dashboard"
      produces "application/json"

      response "200", "metrics returned" do
        schema "$ref" => "#/components/schemas/dashboard_metrics"

        before do
          workshop = create(:workshop)
          s1 = create(:session, workshop: workshop, capacity: 2,
            starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
          create(:registration, session: s1, status: "held")
          create(:registration, session: s1, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)
          create(:registration, session: s1, status: "waitlisted")
        end

        run_test! do |response|
          json = response.parsed_body
          expect(json).to include(
            "upcoming_scheduled_sessions", "total_held", "total_confirmed",
            "total_waitlisted", "expired_holds_today", "full_sessions",
            "top_waitlisted_sessions"
          )
        end
      end
    end
  end
end
