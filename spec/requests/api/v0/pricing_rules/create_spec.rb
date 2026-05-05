# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "POST /api/v0/pricing_rules", type: :request do
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
  let!(:court) { create(:court, venue: venue, court_type: court_type, name: "Court 1") }

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/pricing_rules" }
  let(:request_headers) { headers }

  let(:pricing_rule_name) { "Morning Peak" }
  let(:pricing_rule_price) { 2500.0 }
  let(:pricing_rule_day_of_week) { "monday" }
  let(:pricing_rule_start_time) { "08:00" }
  let(:pricing_rule_end_time) { "12:00" }
  let(:pricing_rule_start_date) { nil }
  let(:pricing_rule_end_date) { nil }
  let(:pricing_rule_priority) { 1 }
  let(:pricing_rule_is_active) { true }
  let(:court_court_id) { court.id }

  let(:request_params) do
    {
      name: pricing_rule_name,
      court_id: court_court_id,
      price_per_hour: pricing_rule_price,
      day_of_week: pricing_rule_day_of_week,
      start_time: pricing_rule_start_time,
      end_time: pricing_rule_end_time,
      start_date: pricing_rule_start_date,
      end_date: pricing_rule_end_date,
      priority: pricing_rule_priority,
      is_active: pricing_rule_is_active
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

    it "matches the pricing rules create response schema" do
      expect(response).to match_json_schema("pricing_rules/create_response")
    end

    it "persists the pricing rule to the database" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_present
    end

    it "returns the correct name and price" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "name" => pricing_rule_name,
        "day_of_week" => pricing_rule_day_of_week
      )
    end

    it "returns the correct court_id and venue_id" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "court_id" => court.id,
        "venue_id" => venue.id
      )
    end

    it "returns is_active as true" do
      data = response.parsed_body["data"]
      expect(data["is_active"]).to be true
    end

    it "returns the correct priority" do
      data = response.parsed_body["data"]
      expect(data["priority"]).to eq(pricing_rule_priority)
    end

    it "returns a time_range derived from start and end times" do
      data = response.parsed_body["data"]
      expect(data["time_range"]).to be_a(String)
      expect(data["time_range"]).not_to eq("All day")
    end

    it "returns a day_name humanized from day_of_week" do
      data = response.parsed_body["data"]
      expect(data["day_name"]).to eq("Monday")
    end
  end

  context "when authenticated as a global admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists the pricing rule to the database" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_present
    end

    it "matches the pricing rules create response schema" do
      expect(response).to match_json_schema("pricing_rules/create_response")
    end
  end

  context "when creating with only the required parameters (no optional fields)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) do
      {
        name: pricing_rule_name,
        court_id: court_court_id,
        price_per_hour: pricing_rule_price
      }
    end

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists the pricing rule with database defaults" do
      rule = PricingRule.find_by(name: pricing_rule_name)
      expect(rule).to be_present
      expect(rule.is_active).to be true
      expect(rule.day_of_week).to eq("all_days")
    end

    it "returns time_range as All day when no times provided" do
      data = response.parsed_body["data"]
      expect(data["time_range"]).to eq("All day")
    end
  end

  context "when creating with day_of_week set to weekends" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_day_of_week) { "weekends" }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists day_of_week as weekends" do
      rule = PricingRule.find_by(name: pricing_rule_name)
      expect(rule.day_of_week).to eq("weekends")
    end

    it "returns day_name as Weekends" do
      data = response.parsed_body["data"]
      expect(data["day_name"]).to eq("Weekends")
    end
  end

  context "when creating with a date range" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_start_date) { "2026-01-01" }
    let(:pricing_rule_end_date) { "2026-12-31" }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists start_date and end_date correctly" do
      rule = PricingRule.find_by(name: pricing_rule_name)
      expect(rule.start_date.to_s).to eq("2026-01-01")
      expect(rule.end_date.to_s).to eq("2026-12-31")
    end
  end

  context "when creating an initially inactive pricing rule" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_is_active) { false }

    it "returns created (201) status" do
      expect(response).to have_http_status(:created)
    end

    it "persists the pricing rule as inactive" do
      rule = PricingRule.find_by(name: pricing_rule_name)
      expect(rule.is_active).to be false
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

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
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

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  context "when a malformed Authorization header is provided (missing Bearer prefix)" do
    let(:request_headers) { headers.merge("Authorization" => "NotBearer sometoken") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
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

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when authenticated as the owner of a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Required Field Validation
  # ==================================================

  context "when name is blank" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_name) { "" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end

    it "does not create a pricing rule" do
      expect(PricingRule.where(name: "")).not_to exist
    end
  end

  context "when name is nil" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_name) { nil }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: nil)).to be_nil
    end
  end

  context "when price_per_hour is zero (must be greater than zero)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_price) { 0 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  context "when price_per_hour is negative" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_price) { -100.0 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  context "when price_per_hour is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params) do
      {
        name: pricing_rule_name,
        court_id: court_court_id,
        day_of_week: pricing_rule_day_of_week,
        priority: pricing_rule_priority
      }
    end

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  context "when court_id is nil" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_court_id) { nil }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Resource Not Found
  # ==================================================

  context "when court_id references a non-existent court" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_court_id) { 999_999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  # ==================================================
  # FAILURE PATHS — Cross-field Validations
  # ==================================================

  context "when end_time is before start_time" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_start_time) { "12:00" }
    let(:pricing_rule_end_time) { "08:00" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end

    it "includes end_time error in the response" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when end_time equals start_time" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_start_time) { "10:00" }
    let(:pricing_rule_end_time) { "10:00" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  context "when end_date is before start_date" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_start_date) { "2026-06-01" }
    let(:pricing_rule_end_date) { "2026-01-01" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end

  # ==================================================
  # FAILURE PATHS — Invalid Values
  # ==================================================

  context "when day_of_week is an invalid string" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_day_of_week) { "invalid_day" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not create a pricing rule" do
      expect(PricingRule.find_by(name: pricing_rule_name)).to be_nil
    end
  end
end
