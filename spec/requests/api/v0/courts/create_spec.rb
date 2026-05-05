# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "POST /api/v0/courts", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_role) { create(:role, :owner) }
  let(:admin_role) { create(:role, :admin) }
  let(:customer_role) { create(:role, :customer) }

  let(:owner_user) { create(:user, email: "owner@example.com") }
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:customer_user) { create(:user, email: "customer@example.com") }
  let(:other_owner_user) { create(:user, email: "other_owner@example.com") }

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    customer_user.assign_role(customer_role)
    other_owner_user.assign_role(owner_role)
  end

  let!(:court_type) { create(:court_type, name: "Badminton") }
  let!(:venue) { create(:venue, name: "Alpha Arena", owner: owner_user) }

  # Pre-created court used to test duplicate name validation (scoped to venue)
  let!(:pre_existing_court) do
    create(:court, venue: venue, court_type: court_type, name: "Duplicate Court Name")
  end

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/courts" }
  let(:request_headers) { headers }

  let(:court_name) { "Court Alpha" }
  let(:court_description) { "A premium indoor badminton court" }
  let(:court_venue_id) { venue.id }
  let(:court_court_type_id) { court_type.id }
  let(:court_slot_interval) { 60 }
  let(:court_requires_approval) { false }
  let(:court_is_active) { true }

  let(:request_params) do
    {
      venue_id: court_venue_id,
      court_type_id: court_court_type_id,
      name: court_name,
      description: court_description,
      slot_interval: court_slot_interval,
      requires_approval: court_requires_approval,
      is_active: court_is_active
    }
  end

  before do
    post endpoint, params: request_params.to_json, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner with valid complete parameters" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "matches the courts create response schema" do
      expect(response).to match_json_schema("courts/create_response")
    end

    it "persists the court to the database" do
      expect(Court.find_by(name: court_name)).to be_present
    end

    it "returns the correct court name and description" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "name" => court_name,
        "description" => court_description
      )
    end

    it "returns the correct court settings" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "slot_interval" => court_slot_interval,
        "requires_approval" => court_requires_approval,
        "is_active" => court_is_active
      )
    end

    it "returns the correct venue_id and court_type_id" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "venue_id" => venue.id,
        "court_type_id" => court_type.id
      )
    end

    it "returns the embedded court_type with id and name" do
      data = response.parsed_body["data"]
      expect(data["court_type"]).to include(
        "id" => court_type.id,
        "name" => court_type.name
      )
    end

    it "returns the embedded venue with id and name" do
      data = response.parsed_body["data"]
      expect(data["venue"]).to include(
        "id" => venue.id,
        "name" => venue.name
      )
    end

    it "returns pricing_rules as an empty array" do
      data = response.parsed_body["data"]
      expect(data["pricing_rules"]).to eq([])
    end

    it "returns an images array" do
      data = response.parsed_body["data"]
      expect(data["images"]).to be_an(Array)
    end
  end

  context "when authenticated as a global admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists the court to the database" do
      expect(Court.find_by(name: court_name)).to be_present
    end

    it "matches the courts create response schema" do
      expect(response).to match_json_schema("courts/create_response")
    end
  end

  context "when creating with only the required parameters (no optional fields)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) do
      {
        venue_id: court_venue_id,
        court_type_id: court_court_type_id,
        name: court_name
      }
    end

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "applies the database default slot_interval of 60 minutes" do
      court = Court.find_by(name: court_name)
      expect(court.slot_interval).to eq(60)
    end

    it "applies the database default requires_approval of false" do
      court = Court.find_by(name: court_name)
      expect(court.requires_approval).to be false
    end

    it "applies the database default is_active of true" do
      court = Court.find_by(name: court_name)
      expect(court.is_active).to be true
    end
  end

  context "when creating with a custom slot_interval" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_slot_interval) { 90 }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists the custom slot_interval" do
      court = Court.find_by(name: court_name)
      expect(court.slot_interval).to eq(90)
    end
  end

  context "when creating a court that requires manual booking approval" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_requires_approval) { true }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists requires_approval as true" do
      court = Court.find_by(name: court_name)
      expect(court.requires_approval).to be true
    end
  end

  context "when creating a court that is initially inactive" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_is_active) { false }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists the court as inactive" do
      court = Court.find_by(name: court_name)
      expect(court.is_active).to be false
    end
  end

  context "when a court with the same name exists in a different venue (uniqueness is per-venue)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:other_venue) { create(:venue, name: "Beta Arena", owner: other_owner_user) }

    before do
      # Create a court with the same name in a different venue before the POST runs
      create(:court, venue: other_venue, court_type: court_type, name: court_name)
    end

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "creates the court in the correct venue" do
      expect(Court.find_by(name: court_name, venue_id: venue.id)).to be_present
    end
  end

  # ==================================================
  # FAILURE PATHS — Authentication
  # ==================================================

  context "when no authentication token is provided" do
    let(:request_headers) { headers }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end

    it "returns a failure response" do
      expect(response.parsed_body).to include("success" => false)
    end
  end

  context "when an invalid JWT token is provided" do
    let(:request_headers) { headers.merge("Authorization" => "Bearer invalid_token_xyz") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  context "when a malformed Authorization header is provided (missing Bearer prefix)" do
    let(:request_headers) { headers.merge("Authorization" => "NotBearer sometoken") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Authorization
  # ==================================================

  context "when authenticated as a customer (no venue management permissions)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when authenticated as the owner of a different venue (not this venue's owner)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Required Field Validation
  # ==================================================

  context "when the court name is blank" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_name) { "" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end

    it "does not create a court" do
      expect(Court.where(name: "")).not_to exist
    end
  end

  context "when the court name is nil" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_name) { nil }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "when venue_id is nil" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_venue_id) { nil }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  context "when court_type_id is nil" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_court_type_id) { nil }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Resource Not Found
  # ==================================================

  context "when venue_id references a non-existent venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_venue_id) { 999_999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when court_type_id references a non-existent court type" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_court_type_id) { 999_999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Model-Level Validations
  # ==================================================

  context "when a court with the same name already exists in the same venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_name) { "Duplicate Court Name" } # matches pre_existing_court created at the top

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a duplicate court" do
      expect(Court.where(name: "Duplicate Court Name", venue: venue).count).to eq(1)
    end

    it "includes validation errors in the response" do
      expect(response.parsed_body["errors"]).to be_present
    end
  end

  context "when slot_interval is zero (must be greater than zero)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_slot_interval) { 0 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a court" do
      expect(Court.find_by(name: court_name)).to be_nil
    end
  end

  context "when slot_interval is negative" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_slot_interval) { -30 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
