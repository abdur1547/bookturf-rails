# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/pricing_rules/:id", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_role)        { create(:role, :owner) }
  let(:admin_role)        { create(:role, :admin) }
  let(:customer_role)     { create(:role, :customer) }
  let(:receptionist_role) { create(:role, :receptionist) }

  let(:owner_user)        { create(:user, email: "owner@example.com") }
  let(:admin_user)        { create(:user, email: "admin@example.com") }
  let(:customer_user)     { create(:user, email: "customer@example.com") }
  let(:receptionist_user) { create(:user, email: "receptionist@example.com") }
  let(:other_owner_user)  { create(:user, email: "other_owner@example.com") }

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    customer_user.assign_role(customer_role)
    receptionist_user.assign_role(receptionist_role)
    other_owner_user.assign_role(owner_role)
  end

  let!(:court_type)  { create(:court_type, name: "Badminton") }
  let!(:venue)       { create(:venue, name: "Alpha Arena", owner: owner_user) }
  let!(:other_venue) { create(:venue, name: "Other Arena", owner: other_owner_user) }
  let!(:court)       { create(:court, venue: venue, court_type: court_type, name: "Court 1") }
  let!(:other_court) { create(:court, venue: other_venue, court_type: court_type, name: "Other Court") }

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

  let!(:other_pricing_rule) do
    create(:pricing_rule,
           venue: other_venue,
           court: other_court,
           name: "Other Venue Rule",
           price_per_hour: 1500.0,
           day_of_week: "saturday",
           start_time: "10:00",
           end_time: "14:00",
           priority: 1,
           is_active: true)
  end

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:pricing_rule_id) { pricing_rule.id }
  let(:endpoint)        { "/api/v0/pricing_rules/#{pricing_rule_id}" }
  let(:request_headers) { headers }

  # Allows contexts to run setup (e.g. creating associations) before the request fires.
  # Override this let! in a nested context to inject pre-request setup.
  let!(:pre_request_setup) { }

  before do
    get endpoint, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as the venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns success true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the pricing rule show response schema" do
      expect(response).to match_json_schema("pricing_rules/show_response")
    end

    it "returns the correct pricing rule" do
      data = response.parsed_body["data"]
      expect(data["id"]).to eq(pricing_rule.id)
      expect(data["name"]).to eq("Evening Peak")
    end

    it "returns the correct court and venue" do
      data = response.parsed_body["data"]
      expect(data["court_id"]).to eq(court.id)
      expect(data["venue_id"]).to eq(venue.id)
    end

    it "returns all required attributes" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "id"          => pricing_rule.id,
        "venue_id"    => venue.id,
        "court_id"    => court.id,
        "name"        => "Evening Peak",
        "day_of_week" => "monday",
        "priority"    => 2,
        "is_active"   => true,
        "day_name"    => "Monday",
        "time_range"  => be_a(String),
        "created_at"  => be_a(String),
        "updated_at"  => be_a(String)
      )
    end

    it "returns a formatted time_range" do
      data = response.parsed_body["data"]
      expect(data["time_range"]).not_to eq("All day")
    end
  end

  context "when authenticated as a global admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the pricing rule show response schema" do
      expect(response).to match_json_schema("pricing_rules/show_response")
    end
  end

  context "when authenticated as a receptionist of the venue" do
    let!(:pre_request_setup) { create(:venue_user, venue: venue, user: receptionist_user) }
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the pricing rule show response schema" do
      expect(response).to match_json_schema("pricing_rules/show_response")
    end
  end

  context "when the rule has no time range (all-day rule)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let!(:all_day_rule) do
      create(:pricing_rule,
             venue: venue,
             court: court,
             name: "All Day Rule",
             price_per_hour: 1000.0,
             day_of_week: "all_days",
             start_time: nil,
             end_time: nil,
             priority: 0,
             is_active: true)
    end
    let(:pricing_rule_id) { all_day_rule.id }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns time_range as All day" do
      expect(response.parsed_body["data"]["time_range"]).to eq("All day")
    end

    it "returns day_name as All Days" do
      expect(response.parsed_body["data"]["day_name"]).to eq("All days")
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

    it "returns a failure response" do
      expect(response.parsed_body).to include("success" => false)
    end
  end

  context "when an invalid JWT token is provided" do
    let(:request_headers) { headers.merge("Authorization" => "Bearer invalid_token_xyz") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when a malformed Authorization header is provided" do
    let(:request_headers) { headers.merge("Authorization" => "NotBearer sometoken") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
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

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when authenticated as the owner of a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when a receptionist tries to view a rule for a venue they don't work at" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
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

  context "when a customer tries to access a non-existent rule" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }
    let(:pricing_rule_id) { 999_999 }

    it "returns forbidden (403) because role check happens before record lookup" do
      expect(response).to have_http_status(:forbidden)
    end
  end
end
