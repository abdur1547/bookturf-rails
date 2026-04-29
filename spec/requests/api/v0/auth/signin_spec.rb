# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Auth::Signin", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }
  let(:user_password) { "password123" }
  let(:user) { create(:user, password: user_password, password_confirmation: user_password) }

  # ==================================================
  # POST /api/v0/auth/signin
  # ==================================================
  describe "POST /api/v0/auth/signin" do
    let(:endpoint) { "/api/v0/auth/signin" }
    let(:request_headers) { headers }
    let(:email) { user.email }
    let(:password) { user_password }

    let(:request_params) do
      {
        email: email,
        password: password
      }
    end

    before do
      user
      post endpoint, params: request_params.to_json, headers: request_headers
    end

    # SUCCESS PATHS
    context "with valid credentials" do
      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the signin response schema" do
        expect(response).to match_json_schema("auth/signin_response")
      end

      it "returns an access token" do
        expect(response.parsed_body[:data][:access_token]).to be_present
      end

      it "returns a refresh token" do
        expect(response.parsed_body[:data][:refresh_token]).to be_present
      end

      it "returns user data" do
        user_data = response.parsed_body[:data][:user]
        expect(user_data[:email]).to eq(user.email)
        expect(user_data[:full_name]).to eq(user.full_name)
      end

      it "sets the Authorization response header" do
        expect(response.headers["Authorization"]).to be_present
      end

      it "access token starts with Bearer prefix" do
        expect(response.parsed_body[:data][:access_token]).to start_with("Bearer ")
      end

      it "returns user id in user data" do
        expect(response.parsed_body[:data][:user][:id]).to eq(user.id)
      end
    end

    # FAILURE PATHS
    context "with wrong password" do
      let(:password) { "wrongpassword" }

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

    context "with non-existent email" do
      let(:email) { "nonexistent@example.com" }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end
    end

    context "when email is blank" do
      let(:email) { "" }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when password is blank" do
      let(:password) { "" }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when email is missing from params" do
      let(:request_params) { { password: password } }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when password is missing from params" do
      let(:request_params) { { email: email } }

      it "returns unauthorized" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with email in different case" do
      let(:email) { user.email.upcase }

      it "returns ok because email is normalized before lookup" do
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
