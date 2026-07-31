require "swagger_helper"

RSpec.describe "API V1 Registrations", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:workshop) { create(:workshop, title: "API Design", topic: "design") }
  let(:session) do
    create(:session, workshop: workshop, capacity: 3,
      starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  path "/api/v1/sessions/{session_id}/registrations" do
    post("create registration") do
      tags "Registrations"
      consumes "application/json"
      produces "application/json"
      parameter name: :session_id, in: :path, type: :integer, required: true
      parameter name: :registration, in: :body, schema: {
        type: :object,
        properties: {
          session_id: { type: :integer },
          attendee: {
            type: :object,
            properties: {
              name: { type: :string },
              email: { type: :string }
            },
            required: %w[name email]
          }
        },
        required: %w[session_id attendee]
      }

      response "201", "registration created" do
        let(:session_id) { session.id }
        let(:registration) do
          { session_id: session.id, attendee: { name: "Alice", email: "alice@example.com" } }
        end

        schema "$ref" => "#/components/schemas/registration_create"

        run_test! do |response|
          json = response.parsed_body
          expect(%w[held waitlisted]).to include(json["status"])
          expect(json["attendee"]["name"]).to eq("Alice")
        end
      end

      response "422", "invalid registration" do
        let(:session_id) { session.id }
        let(:registration) { { session_id: session.id, attendee: { name: "", email: "" } } }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end

  path "/api/v1/registrations/{id}/confirm" do
    post("confirm registration") do
      tags "Registrations"
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "registration confirmed" do
        let(:id) { registration.id }
        let!(:registration) do
          create(:registration, session: session, status: "held",
            hold_expires_at: current_time + 30.minutes)
        end

        schema "$ref" => "#/components/schemas/registration_create"

        run_test! do |response|
          json = response.parsed_body
          expect(json["status"]).to eq("confirmed")
          expect(json["confirmed_at"]).to be_present
        end
      end

      response "404", "registration not found" do
        let(:id) { 999999 }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end

      response "409", "conflict (hold expired)" do
        let(:id) { registration.id }
        let!(:registration) do
          create(:registration, session: session, status: "held",
            hold_expires_at: current_time - 1.minute)
        end

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end

  path "/api/v1/registrations/{id}/cancel" do
    post("cancel registration") do
      tags "Registrations"
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "registration cancelled" do
        let(:id) { registration.id }
        let!(:registration) do
          create(:registration, session: session, status: "held",
            hold_expires_at: current_time + 30.minutes)
        end

        schema "$ref" => "#/components/schemas/registration_create"

        run_test! do |response|
          json = response.parsed_body
          expect(json["status"]).to eq("cancelled")
          expect(json["cancelled_at"]).to be_present
        end
      end

      response "404", "registration not found" do
        let(:id) { 999999 }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end
end
