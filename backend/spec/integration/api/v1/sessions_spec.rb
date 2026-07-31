require "swagger_helper"

RSpec.describe "API V1 Sessions", type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let(:current_time) { Time.zone.parse("2026-07-30 14:00:00 UTC") }
  let(:workshop) { create(:workshop, title: "Rails Deep Dive", topic: "rails", description: "Advanced Rails patterns") }
  let(:session) do
    create(:session, workshop: workshop, capacity: 5,
      starts_at: current_time + 1.day, ends_at: current_time + 1.day + 2.hours)
  end

  around do |example|
    travel_to(current_time) { example.run }
  end

  path "/api/v1/workshops/{workshop_id}/sessions" do
    post("create session") do
      tags "Sessions"
      consumes "application/json"
      produces "application/json"
      parameter name: :workshop_id, in: :path, type: :integer, required: true
      parameter name: :session, in: :body, schema: {
        type: :object,
        properties: {
          session: {
            type: :object,
            properties: {
              starts_at: { type: :string, format: "date-time" },
              ends_at: { type: :string, format: "date-time" },
              capacity: { type: :integer },
              status: { type: :string, enum: %w[scheduled cancelled completed] }
            },
            required: %w[starts_at ends_at capacity status]
          }
        },
        required: %w[session]
      }

      response "201", "session created" do
        let(:workshop_id) { workshop.id }
        let(:session) do
          {
            session: {
              starts_at: (current_time + 1.day).iso8601,
              ends_at: (current_time + 1.day + 2.hours).iso8601,
              capacity: 10,
              status: "scheduled"
            }
          }
        end

        schema "$ref" => "#/components/schemas/session"

        run_test! do |response|
          json = response.parsed_body
          expect(json["capacity"]).to eq(10)
          expect(json["status"]).to eq("scheduled")
        end
      end

      response "404", "workshop not found" do
        let(:workshop_id) { 999999 }
        let(:session) do
          {
            session: {
              starts_at: (current_time + 1.day).iso8601,
              ends_at: (current_time + 1.day + 2.hours).iso8601,
              capacity: 10,
              status: "scheduled"
            }
          }
        end

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end

      response "422", "invalid session" do
        let(:workshop_id) { workshop.id }
        let(:session) do
          {
            session: {
              starts_at: (current_time + 2.hours).iso8601,
              ends_at: (current_time + 1.hour).iso8601,
              capacity: 0,
              status: "invalid"
            }
          }
        end

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end

  path "/api/v1/sessions" do
    get("list sessions") do
      tags "Sessions"
      produces "application/json"
      parameter name: :topic, in: :query, type: :string, required: false,
                description: "Filter by workshop topic"
      parameter name: :from, in: :query, type: :string, format: "date-time", required: false,
                description: "Filter sessions starting at or after this time (ISO 8601)"
      parameter name: :to, in: :query, type: :string, format: "date-time", required: false,
                description: "Filter sessions ending at or before this time (ISO 8601)"
      parameter name: :available, in: :query, type: :string, required: false,
                description: 'Set to "true" to show only sessions with available seats',
                enum: %w[true false]
      parameter name: :sort, in: :query, type: :string, required: false,
                description: "Sort column (starts_at, capacity, created_at)",
                enum: %w[starts_at capacity created_at]
      parameter name: :order, in: :query, type: :string, required: false,
                description: "Sort direction (asc, desc)",
                enum: %w[asc desc]
      parameter name: :page, in: :query, type: :integer, required: false,
                description: "Page number"
      parameter name: :per_page, in: :query, type: :integer, required: false,
                description: "Results per page (max 50)"

      response "200", "sessions found" do
        schema "$ref" => "#/components/schemas/session_list"

        before do
          session
        end

        run_test! do |response|
          json = response.parsed_body
          expect(json["sessions"]).to be_present
          expect(json["pagination"]).to be_present
        end
      end
    end
  end

  path "/api/v1/sessions/{id}" do
    get("show session") do
      tags "Sessions"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "session found" do
        let(:id) { session.id }

        schema "$ref" => "#/components/schemas/session_detail"

        run_test! do |response|
          json = response.parsed_body
          expect(json["availability"]).to be_present
          expect(json["workshop"]["description"]).to be_present
        end
      end

      response "404", "session not found" do
        let(:id) { 999999 }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end

  path "/api/v1/sessions/{id}/cancel" do
    post("cancel session") do
      tags "Sessions"
      consumes "application/json"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :cancellation_request, in: :body, schema: {
        type: :object,
        properties: {
          cancellation_reason: { type: :string, example: "Organizer emergency" }
        },
        required: %w[cancellation_reason]
      }

      response "200", "session cancelled" do
        let(:id) { session.id }
        let(:cancellation_request) { { cancellation_reason: "Organizer emergency" } }

        before do
          create(:registration, session: session, status: "held")
          create(:registration, session: session, status: "confirmed", hold_expires_at: nil, confirmed_at: current_time)
          create(:registration, session: session, status: "waitlisted", hold_expires_at: nil)
        end

        schema "$ref" => "#/components/schemas/session_cancellation"

        run_test! do |response|
          json = response.parsed_body
          expect(json["session"]["status"]).to eq("cancelled")
          expect(json["session"]["cancellation_reason"]).to eq("Organizer emergency")
          expect(json["cancelled_registrations"]).to eq("held" => 1, "confirmed" => 1, "waitlisted" => 1)
          expect(json["cancelled_count"]).to eq(3)
        end
      end

      response "422", "missing cancellation reason" do
        let(:id) { session.id }
        let(:cancellation_request) { { cancellation_reason: "" } }

        schema "$ref" => "#/components/schemas/error"

        run_test! do |response|
          json = response.parsed_body
          expect(json["error"]["code"]).to eq("validation_error")
        end
      end

      response "404", "session not found" do
        let(:id) { 999999 }
        let(:cancellation_request) { { cancellation_reason: "Organizer emergency" } }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end

      response "409", "session cannot be cancelled" do
        let(:id) { session.id }
        let(:cancellation_request) { { cancellation_reason: "Organizer emergency" } }

        before do
          session.update!(status: "completed")
        end

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end
end