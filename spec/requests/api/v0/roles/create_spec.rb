# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "POST /api/v0/roles", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user) { create(:user) }
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:unrelated_user) { create(:user) }
  let(:staff_user) { create(:user) }

  let!(:venue) { create(:venue, owner: owner_user) }

  let(:create_roles_permission) { create(:permission, :create_roles) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }

  before do
    staff_role.permissions << create_roles_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
  end

  let!(:perm1) { create(:permission, :read_bookings) }
  let!(:perm2) { create(:permission, :read_courts) }

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/roles" }
  let(:role_name) { "Court Manager" }
  let(:permission_ids) { [ perm1.id, perm2.id ] }

  let(:request_params) do
    {
      name: role_name,
      venue_id: venue.id,
      permission_ids: permission_ids
    }
  end

  let(:request_headers) { headers }
  let(:pre_existing_role_name) { nil }

  before do
    create(:role, name: pre_existing_role_name, venue: venue) if pre_existing_role_name.present?
    post endpoint, params: request_params.to_json, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "returns success: true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the create response schema" do
      expect(response).to match_json_schema("roles/create_response")
    end

    it "returns the created role with correct attributes" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "name" => role_name,
        "venue_id" => venue.id,
        "permissions" => be_an(Array)
      )
    end

    it "assigns the specified permissions to the role" do
      data = response.parsed_body["data"]
      returned_ids = data["permissions"].map { |p| p["id"] }
      expect(returned_ids).to match_array([ perm1.id, perm2.id ])
    end

    it "persists the role to the database" do
      expect(Role.find_by(name: role_name, venue: venue)).to be_present
    end

    context "with no permissions (empty array)" do
      let(:permission_ids) { [] }

      it "returns created (201) status" do
        expect(response).to have_http_status(:created)
      end

      it "creates role with no permissions" do
        data = response.parsed_body["data"]
        expect(data["permissions"]).to eq([])
      end
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "matches the create response schema" do
      expect(response).to match_json_schema("roles/create_response")
    end
  end

  context "when authenticated as staff with create permission on roles" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when name is blank" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:role_name) { "" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a role" do
      expect(Role.find_by(name: "", venue: venue)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when name is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { venue_id: venue.id, permission_ids: [] } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when name already exists for the same venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pre_existing_role_name) { role_name }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when venue_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { name: role_name, venue_id: 999999, permission_ids: [] } }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when venue_id is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { name: role_name, permission_ids: [] } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when permission_ids is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { name: role_name, venue_id: venue.id } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when permission_ids contains invalid IDs" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:permission_ids) { [ 99999, 88888 ] }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a role" do
      expect(Role.find_by(name: role_name, venue: venue)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when authenticated as unrelated user (no venue access)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a role" do
      expect(Role.find_by(name: role_name, venue: venue)).to be_nil
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create a role" do
      expect(Role.find_by(name: role_name, venue: venue)).to be_nil
    end
  end
end
