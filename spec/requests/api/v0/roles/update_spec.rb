# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PATCH /api/v0/roles/:id", type: :request do
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

  let(:update_roles_permission) { create(:permission, :update_roles) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }

  before do
    staff_role.permissions << update_roles_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
  end

  let!(:perm1) { create(:permission, :read_bookings) }
  let!(:perm2) { create(:permission, :read_courts) }
  let!(:test_role) { create(:role, name: "Original Name", venue: venue) }

  before { test_role.permissions << perm1 }

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:role_id) { test_role.id }
  let(:endpoint) { "/api/v0/roles/#{role_id}" }
  let(:updated_name) { "Updated Role Name" }
  let(:updated_permission_ids) { nil }
  let(:request_headers) { headers }
  let(:conflicting_role_name) { nil }

  let(:request_params) do
    params = {}
    params[:name] = updated_name unless updated_name.nil?
    params[:permission_ids] = updated_permission_ids unless updated_permission_ids.nil?
    params
  end

  before do
    create(:role, name: conflicting_role_name, venue: venue) if conflicting_role_name.present?
    patch endpoint, params: request_params.to_json, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner updating name" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns success: true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the update response schema" do
      expect(response).to match_json_schema("roles/update_response")
    end

    it "returns the updated role name" do
      data = response.parsed_body["data"]
      expect(data["name"]).to eq("Updated Role Name")
    end

    it "persists the name change in the database" do
      test_role.reload
      expect(test_role.name).to eq("Updated Role Name")
    end

    it "keeps the original permissions when permission_ids not provided" do
      test_role.reload
      expect(test_role.permissions.pluck(:id)).to include(perm1.id)
    end
  end

  context "when updating permissions only" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:updated_name) { nil }
    let(:updated_permission_ids) { [perm2.id] }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "syncs permissions to the new set" do
      test_role.reload
      expect(test_role.permissions.pluck(:id)).to eq([perm2.id])
    end

    it "removes old permissions not in the new list" do
      test_role.reload
      expect(test_role.permissions.pluck(:id)).not_to include(perm1.id)
    end

    it "returns updated permissions in response" do
      data = response.parsed_body["data"]
      expect(data["permissions"].map { |p| p["id"] }).to eq([perm2.id])
    end
  end

  context "when clearing all permissions" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:updated_name) { nil }
    let(:updated_permission_ids) { [] }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "removes all permissions from the role" do
      test_role.reload
      expect(test_role.permissions.count).to eq(0)
    end
  end

  context "when updating both name and permissions" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:updated_permission_ids) { [perm1.id, perm2.id] }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "updates both name and permissions" do
      test_role.reload
      expect(test_role.name).to eq("Updated Role Name")
      expect(test_role.permissions.pluck(:id)).to match_array([perm1.id, perm2.id])
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the update response schema" do
      expect(response).to match_json_schema("roles/update_response")
    end
  end

  context "when authenticated as staff with update permission on roles" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when name is blank" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:updated_name) { "" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the role" do
      test_role.reload
      expect(test_role.name).to eq("Original Name")
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when name already exists for the same venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:conflicting_role_name) { updated_name }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the role" do
      test_role.reload
      expect(test_role.name).to eq("Original Name")
    end
  end

  context "when permission_ids contains invalid IDs" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:updated_name) { nil }
    let(:updated_permission_ids) { [99999] }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the permissions" do
      test_role.reload
      expect(test_role.permissions.pluck(:id)).to include(perm1.id)
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

  context "when authenticated as unrelated user" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not update the role" do
      test_role.reload
      expect(test_role.name).to eq("Original Name")
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
