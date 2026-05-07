# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DELETE /api/v0/roles/:id", type: :request do
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

  let(:delete_roles_permission) { create(:permission, :delete_roles) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }

  before do
    staff_role.permissions << delete_roles_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
  end

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:role_id) { test_role.id }
  let(:endpoint) { "/api/v0/roles/#{role_id}" }
  let(:request_headers) { headers }

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner deleting a role with no memberships" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:test_role) { create(:role, name: "Role To Delete", venue: venue) }

    before { delete endpoint, headers: request_headers }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns success: true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the destroy response schema" do
      expect(response).to match_json_schema("roles/destroy_response")
    end

    it "returns a success message" do
      data = response.parsed_body["data"]
      expect(data["message"]).to eq("Role deleted successfully")
    end

    it "removes the role from the database" do
      expect(Role.find_by(id: test_role.id)).to be_nil
    end
  end

  context "when deleting a role that has permissions but no memberships" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:test_role) { create(:role, name: "Role With Perms", venue: venue) }

    before do
      test_role.permissions << create(:permission, :read_bookings)
      delete endpoint, headers: request_headers
    end

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "removes the role from the database" do
      expect(Role.find_by(id: test_role.id)).to be_nil
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }
    let!(:test_role) { create(:role, name: "Admin Deleted Role", venue: venue) }

    before { delete endpoint, headers: request_headers }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "removes the role from the database" do
      expect(Role.find_by(id: test_role.id)).to be_nil
    end
  end

  context "when authenticated as staff with delete permission on roles" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }
    let!(:test_role) { create(:role, name: "Staff Deleted Role", venue: venue) }

    before { delete endpoint, headers: request_headers }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when role has active venue memberships" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:test_role) { create(:role, name: "Role With Members", venue: venue) }
    let(:assigned_user) { create(:user) }

    before do
      create(:venue_membership, user: assigned_user, venue: venue, role: test_role)
      delete endpoint, headers: request_headers
    end

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "keeps the role in the database" do
      expect(Role.find_by(id: test_role.id)).to be_present
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end

    it "returns an appropriate error message" do
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  context "when role belongs to a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:other_role) { create(:role, name: "Other Venue Role", venue: other_venue) }
    let(:role_id) { other_role.id }

    before { delete endpoint, headers: request_headers }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "keeps the role in the database" do
      expect(Role.find_by(id: other_role.id)).to be_present
    end
  end

  context "when role does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:role_id) { 999999 }

    before { delete endpoint, headers: request_headers }

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

    before { delete endpoint, headers: request_headers }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when authenticated as unrelated user" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }
    let!(:test_role) { create(:role, name: "Protected Role", venue: venue) }

    before { delete endpoint, headers: request_headers }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "keeps the role in the database" do
      expect(Role.find_by(id: test_role.id)).to be_present
    end
  end

  context "when not authenticated" do
    let!(:test_role) { create(:role, name: "Unauthenticated Role", venue: venue) }

    before { delete endpoint, headers: headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "keeps the role in the database" do
      expect(Role.find_by(id: test_role.id)).to be_present
    end
  end
end
