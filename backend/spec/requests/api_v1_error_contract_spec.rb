require "rails_helper"

RSpec.describe "API v1 error contract", type: :request do
  describe "GET /api/v1/health" do
    it "returns an OK response from the versioned namespace" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("status" => "ok")
    end

    it "allows the configured local Vue origin" do
      get "/api/v1/health", headers: { "Origin" => "http://localhost:5173" }

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("http://localhost:5173")
    end
  end

  describe "shared error rendering" do
    before do
      stub_const("Api::V1::ErrorContractProbeController", error_contract_probe_controller)

      Rails.application.routes.draw do
        namespace :api do
          namespace :v1 do
            post "error_contract_probe/validation", to: "error_contract_probe#validation"
            post "error_contract_probe/conflict", to: "error_contract_probe#conflict"
            get "error_contract_probe/missing", to: "error_contract_probe#missing"
          end
        end
      end
    end

    after do
      Rails.application.reload_routes!
    end

    let(:error_contract_probe_controller) do
      Class.new(Api::V1::BaseController) do
        def validation
          params.require(:name)
          head :created
        end

        def conflict
          raise Api::Errors::ConflictError.new(
            "Registration cannot be completed",
            details: ["Session capacity has already been claimed"]
          )
        end

        def missing
          raise ActiveRecord::RecordNotFound, "Couldn't find Session"
        end
      end
    end

    it "renders validation errors with the standard envelope" do
      post "/api/v1/error_contract_probe/validation", params: {}

      expect(response).to have_http_status(422)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "validation_error",
          "message" => "param is missing or the value is empty: name",
          "details" => []
        }
      )
    end

    it "renders domain conflicts with the standard envelope" do
      post "/api/v1/error_contract_probe/conflict"

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "registration_conflict",
          "message" => "Registration cannot be completed",
          "details" => ["Session capacity has already been claimed"]
        }
      )
    end

    it "renders missing resources with the standard envelope" do
      get "/api/v1/error_contract_probe/missing"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to eq(
        "error" => {
          "code" => "not_found",
          "message" => "Couldn't find Session",
          "details" => []
        }
      )
    end
  end
end
