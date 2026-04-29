# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Auth::Signup", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  # ==================================================
  # POST /api/v0/auth/signup
  # ==================================================
  describe "POST /api/v0/auth/signup" do
    let(:endpoint) { "/api/v0/auth/signup" }
    let(:request_headers) { headers }
    let(:full_name) { "Jane Doe" }
    let(:email) { "jane@example.com" }
    let(:password) { "password123" }
    let(:pre_existing_user) { nil }

    let(:request_params) do
      {
        full_name: full_name,
        email: email,
        password: password
      }
    end

    before do
      pre_existing_user
      post endpoint, params: request_params.to_json, headers: request_headers
    end

    # SUCCESS PATHS
    context "with valid parameters" do
      it "returns ok status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the signup response schema" do
        expect(response).to match_json_schema("auth/signup_response")
      end

      it "creates a new user in the database" do
        expect(User.find_by(email: email)).to be_present
      end

      it "returns an access token" do
        expect(response.parsed_body[:data][:access_token]).to be_present
      end

      it "returns a refresh token" do
        expect(response.parsed_body[:data][:refresh_token]).to be_present
      end

      it "returns user data with correct email" do
        expect(response.parsed_body[:data][:user][:email]).to eq(email)
      end

      it "returns user data with correct full_name" do
        expect(response.parsed_body[:data][:user][:full_name]).to eq(full_name)
      end

      it "sets the Authorization response header" do
        expect(response.headers["Authorization"]).to be_present
      end

      it "access token starts with Bearer prefix" do
        expect(response.parsed_body[:data][:access_token]).to start_with("Bearer ")
      end
    end

    # FAILURE PATHS
    context "when full_name is blank" do
      let(:full_name) { "" }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "does not create a user" do
        expect(User.find_by(email: email)).to be_nil
      end

      it "includes full_name in errors" do
        expect(response.parsed_body[:errors].first).to include("full_name")
      end
    end

    context "when full_name is missing" do
      let(:request_params) { { email: email, password: password } }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create a user" do
        expect(User.find_by(email: email)).to be_nil
      end
    end

    context "when email is blank" do
      let(:email) { "" }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end
    end

    context "when email format is invalid" do
      let(:email) { "notanemail" }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "does not create a user" do
        expect(User.find_by(email: email)).to be_nil
      end

      it "includes email in errors" do
        expect(response.parsed_body[:errors].first).to include("email")
      end
    end

    context "when password is too short" do
      let(:password) { "abc" }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "includes password in errors" do
        expect(response.parsed_body[:errors].first).to include("password")
      end

      it "does not create a user" do
        expect(User.find_by(email: email)).to be_nil
      end
    end

    context "when password is blank" do
      let(:password) { "" }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "includes password in errors" do
        expect(response.parsed_body[:errors].first).to include("password")
      end
    end

    context "when email is already taken" do
      let(:pre_existing_user) { create(:user, email: email) }

      it "returns unprocessable entity" do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "matches the error response schema" do
        expect(response).to match_json_schema("error_response")
      end

      it "does not create a duplicate user" do
        expect(User.where(email: email).count).to eq(1)
      end
    end

    context "when email has different case than existing account" do
      let(:pre_existing_user) { create(:user, email: email.downcase) }
      let(:email) { "Jane@Example.COM" }

      it "returns unprocessable entity due to case-insensitive uniqueness" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
