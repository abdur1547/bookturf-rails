# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "POST /api/v0/roles", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user) { create(:user) }
  let(:regular_user) { create(:user) }
  let(:venue) { create(:venue, owner: owner_user) }

  let(:endpoint) { "/api/v0/roles" }
  let(:role_name) { "Court Manager" }

  let(:request_params) do
    { role: { name: role_name } }
  end

  before { venue } # ensure venue is created so owner_user.owned_venues.first works

  context "when authenticated as venue owner" do
    let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns created status" do
      post endpoint, params: request_params.to_json, headers: auth_headers
      expect(response).to have_http_status(:created)
    end

    it "creates a new role scoped to the owner's venue" do
      expect {
        post endpoint, params: request_params.to_json, headers: auth_headers
      }.to change(Role, :count).by(1)

      new_role = Role.find_by(name: role_name)
      expect(new_role.venue_id).to eq(venue.id)
    end

    it "returns the created role in the response" do
      post endpoint, params: request_params.to_json, headers: auth_headers
      data = response.parsed_body["data"]
      expect(data["name"]).to eq(role_name)
      expect(data["venue_id"]).to eq(venue.id)
    end

    context "when name is missing" do
      let(:role_name) { nil }

      it "returns unprocessable entity" do
        post endpoint, params: request_params.to_json, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not create a role" do
        expect {
          post endpoint, params: request_params.to_json, headers: auth_headers
        }.not_to change(Role, :count)
      end
    end

    context "when name already exists for the same venue" do
      before { create(:role, name: role_name, venue: venue) }

      it "returns unprocessable entity" do
        post endpoint, params: request_params.to_json, headers: auth_headers
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when authenticated as a non-owner user" do
    let(:auth_headers) { headers.merge("Authorization" => auth_token_for(regular_user)) }

    it "returns forbidden status" do
      post endpoint, params: request_params.to_json, headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a role" do
      expect {
        post endpoint, params: request_params.to_json, headers: auth_headers
      }.not_to change(Role, :count)
    end
  end

  context "when not authenticated" do
    it "returns unauthorized status" do
      post endpoint, params: request_params.to_json, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
