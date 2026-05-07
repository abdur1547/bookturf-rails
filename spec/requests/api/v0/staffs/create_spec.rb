# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "POST /api/v0/staffs", type: :request do
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

  let(:create_users_permission) { create(:permission, :create_users) }
  let(:staff_role_with_perm) { create(:role, name: "Staff Role", venue: venue) }
  let(:assignable_role) { create(:role, name: "Assignable Role", venue: venue) }
  let(:other_venue_role) { create(:role, name: "Other Venue Role", venue: other_venue) }

  before do
    staff_role_with_perm.permissions << create_users_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role_with_perm)
  end

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/staffs" }
  let(:staff_name) { "New Staff Member" }
  let(:staff_email) { "newstaff@example.com" }
  let(:role_id) { assignable_role.id }

  let(:request_params) do
    {
      name: staff_name,
      venue_id: venue.id,
      email: staff_email,
      role_id: role_id
    }
  end

  let(:request_headers) { headers }

  before do
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
      expect(response).to match_json_schema("staffs/create_response")
    end

    it "returns the new staff member with correct email" do
      data = response.parsed_body["data"]
      expect(data["email"]).to eq(staff_email)
      expect(data["full_name"]).to eq(staff_name)
    end

    it "creates the user in the database" do
      expect(User.find_by(email: staff_email)).to be_present
    end

    it "creates a venue membership" do
      new_user = User.find_by(email: staff_email)
      expect(VenueMembership.exists?(user: new_user, venue: venue)).to be true
    end

    context "when the user already has an account but is not a venue member" do
      let(:existing_user) { create(:user, email: "existing@example.com") }
      let(:staff_email) { existing_user.email }
      let(:staff_name) { "Updated Name" }

      it "returns created (201) status" do
        expect(response).to have_http_status(:created)
      end

      it "returns the existing user (not a new user)" do
        data = response.parsed_body["data"]
        expect(data["id"]).to eq(existing_user.id)
      end

      it "creates a venue membership for the existing user" do
        expect(VenueMembership.exists?(user: existing_user, venue: venue)).to be true
      end
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "matches the create response schema" do
      expect(response).to match_json_schema("staffs/create_response")
    end
  end

  context "when authenticated as staff with create permission on users" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when the user is already a member of the venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:staff_email) { staff_user.email }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when role_id belongs to a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:role_id) { other_venue_role.id }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a user" do
      expect(User.find_by(email: staff_email)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when role_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:role_id) { 999999 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when name is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { venue_id: venue.id, email: staff_email, role_id: role_id } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when email is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { name: staff_name, venue_id: venue.id, role_id: role_id } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when venue_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) { { name: staff_name, venue_id: 999999, email: staff_email, role_id: role_id } }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when authenticated as unrelated user (no venue access)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a user" do
      expect(User.find_by(email: staff_email)).to be_nil
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create a user" do
      expect(User.find_by(email: staff_email)).to be_nil
    end
  end
end
