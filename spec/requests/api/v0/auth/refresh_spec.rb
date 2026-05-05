# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Auth::Refresh", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:user) { create(:user) }

  # ==================================================
  # POST /api/v0/auth/refresh
  # ==================================================
  describe "POST /api/v0/auth/refresh" do
    let(:endpoint) { "/api/v0/auth/refresh" }
    let(:request_headers) { headers }
    let(:refresh_token_record) { nil }
    let(:refresh_token_value) { nil }

    let(:request_params) do
      { refresh_token: refresh_token_value }
    end

    before do
      refresh_token_record
      post endpoint, params: request_params.to_json, headers: request_headers
    end

    # SUCCESS PATHS
    context "with a valid refresh token passed as param" do
      let(:refresh_token_record) { user.refresh_tokens.create! }
      let(:refresh_token_value) { refresh_token_record.token }

      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the refresh response schema" do
        expect(response).to match_json_schema("auth/refresh_response")
      end

      it "returns a new access token" do
        expect(response.parsed_body[:data][:access_token]).to be_present
      end

      it "returns a new refresh token" do
        expect(response.parsed_body[:data][:refresh_token]).to be_present
      end

      it "access token starts with Bearer prefix" do
        expect(response.parsed_body[:data][:access_token]).to start_with("Bearer ")
      end

      it "sets the Authorization response header" do
        expect(response.headers["Authorization"]).to be_present
      end
    end

    # FAILURE PATHS
    context "without a refresh token" do
      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "returns success false" do
        expect(response.parsed_body[:success]).to be false
      end
    end

    context "with an invalid refresh token" do
      let(:refresh_token_value) { "completely_invalid_token_xyz" }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end
    end
  end
end
