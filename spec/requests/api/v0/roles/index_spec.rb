# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/roles", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user) { create(:user) }
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:unrelated_user) { create(:user) }
  let(:staff_user) { create(:user) }

  let!(:venue) { create(:venue, owner: owner_user) }
  let!(:other_venue) { create(:venue) }

  let!(:role1) { create(:role, name: "Alpha Role", venue: venue) }
  let!(:role2) { create(:role, name: "Beta Role", venue: venue) }
  let!(:other_venue_role) { create(:role, name: "Other Role", venue: other_venue) }

  let(:read_roles_permission) { create(:permission, :read_roles) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }

  before do
    staff_role.permissions << read_roles_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
  end

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/roles" }
  let(:venue_id) { venue.id }
  let(:query_params) { { venue_id: venue_id } }
  let(:request_headers) { headers }

  before do
    params_string = "?#{query_params.to_query}"
    get "#{endpoint}#{params_string}", headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns success: true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("roles/index_response")
    end

    it "returns only roles belonging to the specified venue" do
      data = response.parsed_body["data"]
      returned_ids = data.map { |r| r["id"] }
      expect(returned_ids).to include(role1.id, role2.id)
      expect(returned_ids).not_to include(other_venue_role.id)
    end

    it "returns roles sorted alphabetically" do
      data = response.parsed_body["data"]
      names = data.map { |r| r["name"] }
      expect(names).to eq(names.sort)
    end

    it "includes all required role attributes" do
      data = response.parsed_body["data"].first
      expect(data).to include(
        "id" => be_a(Integer),
        "name" => be_a(String),
        "venue_id" => venue.id,
        "created_at" => be_a(String),
        "updated_at" => be_a(String),
        "permissions" => be_an(Array)
      )
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("roles/index_response")
    end

    it "returns roles for the specified venue" do
      data = response.parsed_body["data"]
      returned_ids = data.map { |r| r["id"] }
      expect(returned_ids).to include(role1.id, role2.id)
    end
  end

  context "when authenticated as staff with read permission on roles" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("roles/index_response")
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when authenticated as unrelated user (no venue access)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "returns success: false" do
      expect(response.parsed_body["success"]).to be false
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when venue_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { 999999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when venue_id is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_params) { {} }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns success: false" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
