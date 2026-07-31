require "swagger_helper"

RSpec.describe "API V1 Health", type: :request do
  path "/api/v1/health" do
    get("health check") do
      tags "Health"
      produces "application/json"

      response "200", "API is healthy" do
        schema type: :object, properties: { status: { type: :string } }

        run_test! do |response|
          expect(response.parsed_body["status"]).to eq("ok")
        end
      end
    end
  end
end
