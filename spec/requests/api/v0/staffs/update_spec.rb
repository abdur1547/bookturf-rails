# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PATCH /api/v0/staffs/:id", type: :request do
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

  let(:update_users_permission) { create(:permission, :update_users) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }
  let(:new_role) { create(:role, name: "New Role", venue: venue) }
  let(:other_venue_role) { create(:role, name: "Other Venue Role", venue: other_venue) }

  let!(:membership) do
    staff_role.permissions << update_users_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
  end

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/staffs/#{staff_user.id}" }
  let(:new_name) { "Updated Name" }
  let(:new_email) { "updated@example.com" }
  let(:role_id) { new_role.id }

  let(:request_params) do
    {
      venue_id: venue.id,
      name: new_name
    }
  end

  let(:request_headers) { headers }

  before do
    patch endpoint, params: request_params.to_json, headers: request_headers
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

    it "matches the update response schema" do
      expect(response).to match_json_schema("staffs/update_response")
    end

    it "updates the staff member's name" do
      expect(response.parsed_body["data"]["full_name"]).to eq(new_name)
    end

    it "persists the name change to the database" do
      expect(staff_user.reload.full_name).to eq(new_name)
    end

    context "when updating only the role" do
      let(:request_params) { { venue_id: venue.id, role_id: new_role.id } }

      it "returns success (200) status" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the role in the membership" do
        expect(membership.reload.role).to eq(new_role)
      end
    end

    context "when updating the email" do
      let(:request_params) { { venue_id: venue.id, email: new_email } }

      it "returns success (200) status" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the email in the database" do
        expect(staff_user.reload.email).to eq(new_email)
      end
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the update response schema" do
      expect(response).to match_json_schema("staffs/update_response")
    end
  end

  context "when authenticated as staff with update permission on users" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when role_id belongs to a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { venue_id: venue.id, role_id: other_venue_role.id } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when role_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { venue_id: venue.id, role_id: 999999 } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when staff member does not belong to the venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:non_member) { create(:user) }
    let(:endpoint) { "/api/v0/staffs/#{non_member.id}" }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when venue_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { venue_id: 999999, name: new_name } }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when venue_id is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { name: new_name } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when authenticated as unrelated user (no venue access)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
