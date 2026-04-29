# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Auth::Signout", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:user) { create(:user) }

  # ==================================================
  # DELETE /api/v0/auth/signout
  # ==================================================
  describe "DELETE /api/v0/auth/signout" do
    let(:endpoint) { "/api/v0/auth/signout" }
    let(:access_token) { auth_token_for(user) }
    let(:request_headers) { headers.merge("Authorization" => access_token) }

    before do
      delete endpoint, headers: request_headers
    end

    # SUCCESS PATHS
    context "when authenticated with a valid token" do
      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the signout response schema" do
        expect(response).to match_json_schema("auth/signout_response")
      end

      it "returns a confirmation message" do
        expect(response.parsed_body[:data][:message]).to include("Signed out")
      end

      it "returns success true" do
        expect(response.parsed_body[:success]).to be true
      end

      it "blacklists the access token" do
        expect(BlacklistedToken.count).to eq(1)
      end

      it "rejects the same token on subsequent authenticated requests" do
        delete endpoint, headers: headers.merge("Authorization" => access_token)
        expect(response).to have_http_status(:unauthorized)
      end
    end

    # FAILURE PATHS
    context "when not authenticated" do
      let(:request_headers) { headers }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "returns success false" do
        expect(response.parsed_body[:success]).to be false
      end

      it "does not blacklist any token" do
        expect(BlacklistedToken.count).to eq(0)
      end
    end

    context "with a malformed token" do
      let(:request_headers) { headers.merge("Authorization" => "Bearer this_is_not_a_valid_jwt") }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end
    end

    context "with an already blacklisted token" do
      before do
        delete endpoint, headers: headers.merge("Authorization" => access_token)
      end

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
