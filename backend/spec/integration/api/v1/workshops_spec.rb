require "swagger_helper"

RSpec.describe "API V1 Workshops", type: :request do
  let(:workshop) { create(:workshop, title: "Rails Deep Dive", topic: "rails", description: "Learn Rails in depth") }

  path "/api/v1/workshops" do
    get("list workshops") do
      tags "Workshops"
      produces "application/json"
      parameter name: :topic, in: :query, type: :string, required: false,
                description: "Filter by topic (case-insensitive)"
      parameter name: :sort, in: :query, type: :string, required: false,
                description: "Sort column (title, created_at, topic)",
                enum: %w[title created_at topic]
      parameter name: :order, in: :query, type: :string, required: false,
                description: "Sort direction (asc, desc)",
                enum: %w[asc desc]
      parameter name: :page, in: :query, type: :integer, required: false,
                description: "Page number"
      parameter name: :per_page, in: :query, type: :integer, required: false,
                description: "Results per page (max 100)"

      response "200", "workshops found" do
        schema "$ref" => "#/components/schemas/workshop_list"

        before do
          workshop
        end

        run_test! do |response|
          json = response.parsed_body
          expect(json["workshops"]).to be_present
          expect(json["pagination"]).to be_present
        end
      end
    end

    post("create workshop") do
      tags "Workshops"
      consumes "application/json"
      produces "application/json"
      parameter name: :workshop, in: :body, schema: {
        type: :object,
        properties: {
          workshop: {
            type: :object,
            properties: {
              title: { type: :string },
              description: { type: :string },
              topic: { type: :string },
              active: { type: :boolean }
            },
            required: %w[title description topic]
          }
        },
        required: %w[workshop]
      }

      response "201", "workshop created" do
        let(:workshop) { { workshop: { title: "Vue Basics", description: "Intro to Vue", topic: "vue" } } }

        schema "$ref" => "#/components/schemas/workshop"

        run_test! do |response|
          expect(response.parsed_body["title"]).to eq("Vue Basics")
        end
      end

      response "422", "invalid workshop" do
        let(:workshop) { { workshop: { title: "", description: "", topic: "" } } }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end

  path "/api/v1/workshops/{id}" do
    get("show workshop") do
      tags "Workshops"
      produces "application/json"
      parameter name: :id, in: :path, type: :integer, required: true

      response "200", "workshop found" do
        let(:id) { workshop.id }

        schema "$ref" => "#/components/schemas/workshop"

        run_test!
      end

      response "404", "workshop not found" do
        let(:id) { 999999 }

        schema "$ref" => "#/components/schemas/error"

        run_test!
      end
    end
  end
end
