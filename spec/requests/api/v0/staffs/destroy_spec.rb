# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DELETE /api/v0/staffs/:id", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user) { create(:user) }
  let(:super_admin_user) { create(:user, :super_admin) }
  let(:unrelated_user) { create(:user) }
  let(:staff_user) { create(:user) }

  let!(:venue) { create(:venue, owner: owner_user) }

  let(:delete_users_permission) { create(:permission, :delete_users) }
  let(:staff_role) { create(:role, name: "Staff Role", venue: venue) }
  let(:deleter_role) { create(:role, name: "Deleter Role", venue: venue) }
  let(:deleter_user) { create(:user) }

  before do
    deleter_role.permissions << delete_users_permission
    create(:venue_membership, user: staff_user, venue: venue, role: staff_role)
    create(:venue_membership, user: deleter_user, venue: venue, role: deleter_role)
  end

  # ==================================================
  # ENDPOINT SETUP
  # ==================================================
  let(:target_user) { staff_user }
  let(:endpoint) { "/api/v0/staffs/#{target_user.id}" }
  let(:venue_id) { venue.id }
  let(:query_params) { { venue_id: venue_id } }
  let(:request_headers) { headers }

  before do
    params_string = "?#{query_params.to_query}"
    delete "#{endpoint}#{params_string}", headers: request_headers
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

    it "matches the destroy response schema" do
      expect(response).to match_json_schema("staffs/destroy_response")
    end

    it "returns a confirmation message" do
      expect(response.parsed_body["data"]["message"]).to be_present
    end

    it "removes the venue membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be false
    end

    it "does not delete the user account" do
      expect(User.exists?(target_user.id)).to be true
    end
  end

  context "when authenticated as super admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(super_admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the destroy response schema" do
      expect(response).to match_json_schema("staffs/destroy_response")
    end

    it "removes the venue membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be false
    end
  end

  context "when authenticated as staff with delete permission on users" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(deleter_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "removes the venue membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be false
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when staff member does not belong to the venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:target_user) { create(:user) }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when staff member id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:endpoint) { "/api/v0/staffs/999999" }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end

  context "when venue_id does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { 999999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not remove the membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be true
    end
  end

  context "when venue_id is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_params) { {} }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not remove the membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be true
    end
  end

  context "when authenticated as unrelated user (no venue access)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unrelated_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not remove the membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be true
    end
  end

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not remove the membership" do
      expect(VenueMembership.exists?(user: target_user, venue: venue)).to be true
    end
  end
end
