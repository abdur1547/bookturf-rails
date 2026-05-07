# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/roles/:id", type: :request do
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

  let(:read_permission) { create(:permission, :read_roles) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }

  before do
    staff_role.permissions << read_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
  end

  let!(:test_role) { create(:role, name: "Test Role", venue: venue) }
  let!(:role_permission) { create(:permission, :read_bookings) }

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:role_id) { test_role.id }
  let(:endpoint) { "/api/v0/roles/#{role_id}" }
  let(:request_headers) { headers }
  let(:permissions_to_add) { [] }

  before do
    permissions_to_add.each { |p| test_role.permissions << p }
    get endpoint, headers: request_headers
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

    it "matches the show response schema" do
      expect(response).to match_json_schema("roles/show_response")
    end

    it "returns the correct role" do
      data = response.parsed_body["data"]
      expect(data["id"]).to eq(test_role.id)
      expect(data["name"]).to eq("Test Role")
      expect(data["venue_id"]).to eq(venue.id)
    end

    it "includes all required role attributes" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "id" => test_role.id,
        "name" => "Test Role",
        "venue_id" => venue.id,
        "created_at" => be_a(String),
        "updated_at" => be_a(String),
        "permissions" => be_an(Array)
      )
    end

    context "with permissions assigned" do
      let(:permissions_to_add) { [ role_permission ] }

      it "includes associated permissions" do
        data = response.parsed_body["data"]
        expect(data["permissions"].length).to eq(1)
        perm = data["permissions"].first
        expect(perm).to include(
          "id" => role_permission.id,
          "resource" => "bookings",
          "action" => "read"
        )
      end
    end

    context "when role has no permissions" do
      it "returns empty permissions array" do
        data = response.parsed_body["data"]
        expect(data["permissions"]).to eq([])
      end
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the show response schema" do
      expect(response).to match_json_schema("roles/show_response")
    end
  end

  context "when authenticated as staff with read permission on roles" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the show response schema" do
      expect(response).to match_json_schema("roles/show_response")
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

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when role belongs to a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:other_role) { create(:role, name: "Other Venue Role", venue: other_venue) }
    let(:role_id) { other_role.id }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when role does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:role_id) { 999999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when role id is non-numeric" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:role_id) { "invalid-id" }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
