# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DELETE /api/v0/pricing_rules/:id", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user)       { create(:user, email: "owner@example.com") }
  let(:admin_user)       { create(:user, :super_admin, email: "admin@example.com") }
  let(:customer_user)    { create(:user, email: "customer@example.com") }
  let(:other_owner_user) { create(:user, email: "other_owner@example.com") }

  let!(:court_type) { create(:court_type, name: "Badminton") }
  let!(:venue)      { create(:venue, name: "Alpha Arena", owner: owner_user) }
  let!(:court)      { create(:court, venue: venue, court_type: court_type, name: "Court 1") }
  let!(:pricing_rule) do
    create(:pricing_rule,
           venue: venue,
           court: court,
           name: "Evening Peak",
           price_per_hour: 2500.0,
           day_of_week: "monday",
           start_time: "18:00",
           end_time: "23:00",
           priority: 2,
           is_active: true)
  end

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:pricing_rule_id)  { pricing_rule.id }
  let(:endpoint)         { "/api/v0/pricing_rules/#{pricing_rule_id}" }
  let(:request_headers)  { headers }

  before do
    delete endpoint, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "removes the pricing rule from the database" do
      expect(PricingRule.find_by(id: pricing_rule.id)).to be_nil
    end

    it "returns success true" do
      expect(response.parsed_body).to include("success" => true)
    end
  end

  context "when authenticated as a global admin (not a venue owner or member)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    # The delete operation scopes lookup to accessible_venue_ids (owned + member venues).
    # An admin who is not a member of the venue cannot find the pricing rule via this endpoint.
    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not delete the pricing rule" do
      expect(PricingRule.find_by(id: pricing_rule.id)).to be_present
    end
  end

  # ==================================================
  # FAILURE PATHS — Base Rule Protection
  # ==================================================

  context "when attempting to delete a base rule" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:base_pricing_rule) do
      create(:pricing_rule,
             venue: venue,
             court: court,
             name: "Regular Price",
             price_per_hour: 1500.0,
             day_of_week: "all_days",
             priority: 0,
             is_active: true,
             base_rule: true)
    end
    let(:pricing_rule_id) { base_pricing_rule.id }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not delete the base rule from the database" do
      expect(PricingRule.find_by(id: base_pricing_rule.id)).to be_present
    end

    it "returns an error message" do
      expect(response.parsed_body["errors"]).to include("Base rules cannot be deleted")
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
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

    it "does not delete the pricing rule" do
      expect(PricingRule.find_by(id: pricing_rule.id)).to be_present
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

    it "does not delete the pricing rule" do
      expect(PricingRule.find_by(id: pricing_rule.id)).to be_present
    end
  end

  context "when a malformed Authorization header is provided (missing Bearer prefix)" do
    let(:request_headers) { headers.merge("Authorization" => "NotBearer sometoken") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ==================================================
  # FAILURE PATHS — Authorization
  # ==================================================

  context "when authenticated as a customer (not a venue owner or member)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    # The delete operation scopes lookup to accessible_venue_ids, so a customer with no
    # venue membership receives 404 rather than 403.
    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not delete the pricing rule" do
      expect(PricingRule.find_by(id: pricing_rule.id)).to be_present
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when authenticated as the owner of a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not delete the pricing rule" do
      expect(PricingRule.find_by(id: pricing_rule.id)).to be_present
    end
  end

  # ==================================================
  # FAILURE PATHS — Resource Not Found
  # ==================================================

  context "when the pricing rule ID does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_id) { 999_999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when the pricing rule ID is a non-numeric string" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:endpoint)        { "/api/v0/pricing_rules/not-a-number" }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end
  end
end
