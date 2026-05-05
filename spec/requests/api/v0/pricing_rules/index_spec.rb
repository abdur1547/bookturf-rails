# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/pricing_rules", type: :request do
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

  let!(:court_type)   { create(:court_type, name: "Badminton") }
  let!(:venue)        { create(:venue, name: "Alpha Arena", owner: owner_user) }
  let!(:other_venue)  { create(:venue, name: "Other Arena", owner: other_owner_user) }
  let!(:court)        { create(:court, venue: venue, court_type: court_type, name: "Court 1") }
  let!(:other_court)  { create(:court, venue: other_venue, court_type: court_type, name: "Other Court") }

  let!(:active_rule) do
    create(:pricing_rule,
           venue: venue,
           court: court,
           name: "Active Morning Rule",
           price_per_hour: 2000.0,
           day_of_week: "monday",
           start_time: "08:00",
           end_time: "12:00",
           priority: 2,
           is_active: true)
  end

  let!(:inactive_rule) do
    create(:pricing_rule,
           venue: venue,
           court: court,
           name: "Inactive Evening Rule",
           price_per_hour: 3000.0,
           day_of_week: "friday",
           start_time: "18:00",
           end_time: "23:00",
           priority: 1,
           is_active: false)
  end

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:endpoint)          { "/api/v0/pricing_rules" }
  let(:request_headers)   { headers }
  let(:query_court_id)    { court.id }
  let(:query_is_active)   { nil }
  let(:query_day_of_week) { nil }

  let(:query_params) do
    params = { court_id: query_court_id }
    params[:is_active]   = query_is_active   unless query_is_active.nil?
    params[:day_of_week] = query_day_of_week unless query_day_of_week.nil?
    params
  end

  # Allows contexts to run setup (e.g. creating associations) before the request fires.
  # Override this let! in a nested context to inject pre-request setup.
  let!(:pre_request_setup) { }

  before do
    params_string = "?#{query_params.to_query}"
    get "#{endpoint}#{params_string}", headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns success true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the pricing rules index response schema" do
      expect(response).to match_json_schema("pricing_rules/index_response")
    end

    it "returns an array of pricing rules for the court" do
      data = response.parsed_body["data"]
      expect(data).to be_an(Array)
      expect(data.length).to eq(2)
    end

    it "returns rules ordered by priority descending then name ascending" do
      data = response.parsed_body["data"]
      priorities = data.map { |r| r["priority"] }
      expect(priorities).to eq(priorities.sort.reverse)
    end

    it "includes all required attributes in each rule" do
      rule_data = response.parsed_body["data"].first
      expect(rule_data).to include(
        "id"          => be_a(Integer),
        "venue_id"    => venue.id,
        "court_id"    => court.id,
        "name"        => be_a(String),
        "day_of_week" => be_a(String),
        "priority"    => be_a(Integer),
        "is_active"   => be_in([ true, false ]),
        "day_name"    => be_a(String),
        "time_range"  => be_a(String),
        "created_at"  => be_a(String),
        "updated_at"  => be_a(String)
      )
    end
  end

  context "when authenticated as a global admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the pricing rules index response schema" do
      expect(response).to match_json_schema("pricing_rules/index_response")
    end

    it "returns pricing rules for the requested court" do
      data = response.parsed_body["data"]
      expect(data).to be_an(Array)
      expect(data.length).to eq(2)
    end
  end

  context "when authenticated as a receptionist of the venue" do
    let!(:pre_request_setup) { create(:venue_user, venue: venue, user: receptionist_user) }
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the pricing rules index response schema" do
      expect(response).to match_json_schema("pricing_rules/index_response")
    end
  end

  context "when filtering by is_active=true" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_is_active) { true }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only active rules" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["is_active"]).to be true
      expect(data.first["name"]).to eq("Active Morning Rule")
    end
  end

  context "when filtering by is_active=false" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_is_active) { false }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only inactive rules" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["is_active"]).to be false
      expect(data.first["name"]).to eq("Inactive Evening Rule")
    end
  end

  context "when filtering by day_of_week=monday" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_day_of_week) { "monday" }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only monday rules" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["day_of_week"]).to eq("monday")
    end
  end

  context "when filtering by day_of_week=friday" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_day_of_week) { "friday" }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only friday rules" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["day_of_week"]).to eq("friday")
    end
  end

  context "when combining is_active and day_of_week filters" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_is_active)   { true }
    let(:query_day_of_week) { "monday" }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only rules matching both filters" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["is_active"]).to be true
      expect(data.first["day_of_week"]).to eq("monday")
    end
  end

  context "when the court has no pricing rules" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }
    let(:query_court_id)  { other_court.id }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns an empty array" do
      data = response.parsed_body["data"]
      expect(data).to eq([])
    end

    it "matches the pricing rules index response schema" do
      expect(response).to match_json_schema("pricing_rules/index_response")
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

  context "when authenticated as owner of a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }
    let(:query_court_id)  { court.id }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when a receptionist tries to list rules for a venue they don't work at" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ==================================================
  # FAILURE PATHS — Resource Not Found
  # ==================================================

  context "when court_id references a non-existent court" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_court_id)  { 999_999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  # ==================================================
  # FAILURE PATHS — Validation
  # ==================================================

  context "when court_id is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_params)    { {} }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when day_of_week filter has an invalid value" do
    let(:request_headers)  { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:query_day_of_week) { "invalid_day" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end
end
