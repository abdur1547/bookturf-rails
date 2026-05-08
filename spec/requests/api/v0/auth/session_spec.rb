# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Auth::Session", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:user) { create(:user) }

  # ==================================================
  # POST /api/v0/auth/session
  # ==================================================
  describe "POST /api/v0/auth/session" do
    let(:endpoint) { "/api/v0/auth/session" }
    let(:request_headers) { headers }
    let(:setup) { nil }

    before do
      setup
      post endpoint, headers: request_headers
    end

    # SUCCESS PATHS
    context "when authenticated with a valid token" do
      let(:request_headers) { headers.merge("Authorization" => auth_token_for(user)) }

      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the session response schema" do
        expect(response).to match_json_schema("auth/session_response")
      end

      it "returns success true" do
        expect(response.parsed_body[:success]).to be true
      end

      it "returns the authenticated user's id" do
        expect(response.parsed_body[:data][:id]).to eq(user.id)
      end

      it "returns the authenticated user's email" do
        expect(response.parsed_body[:data][:email]).to eq(user.email)
      end

      it "returns the authenticated user's full_name" do
        expect(response.parsed_body[:data][:full_name]).to eq(user.full_name)
      end

      it "returns the authenticated user's system_role" do
        expect(response.parsed_body[:data][:system_role]).to eq(user.system_role)
      end
    end

    # FAILURE PATHS
    context "when not authenticated" do
      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "returns success false" do
        expect(response.parsed_body[:success]).to be false
      end
    end

    context "with a malformed token" do
      let(:request_headers) { headers.merge("Authorization" => "Bearer this_is_not_a_valid_jwt") }

      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end
    end

    context "with a blacklisted token" do
      let(:access_token) { auth_token_for(user) }
      let(:request_headers) { headers.merge("Authorization" => access_token) }
      let(:setup) { delete "/api/v0/auth/signout", headers: headers.merge("Authorization" => access_token) }

      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
