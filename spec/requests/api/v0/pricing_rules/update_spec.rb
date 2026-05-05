# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "PATCH /api/v0/pricing_rules/:id", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_role)       { create(:role, :owner) }
  let(:admin_role)       { create(:role, :admin) }
  let(:customer_role)    { create(:role, :customer) }
  let(:receptionist_role) { create(:role, :receptionist) }

  let(:owner_user)       { create(:user, email: "owner@example.com") }
  let(:admin_user)       { create(:user, email: "admin@example.com") }
  let(:customer_user)    { create(:user, email: "customer@example.com") }
  let(:receptionist_user) { create(:user, email: "receptionist@example.com") }
  let(:other_owner_user) { create(:user, email: "other_owner@example.com") }

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    customer_user.assign_role(customer_role)
    receptionist_user.assign_role(receptionist_role)
    other_owner_user.assign_role(owner_role)
  end

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
  let(:pricing_rule_id)         { pricing_rule.id }
  let(:endpoint)                { "/api/v0/pricing_rules/#{pricing_rule_id}" }
  let(:request_headers)         { headers }

  let(:update_name)             { "Updated Morning Deal" }
  let(:update_price)            { 1800.0 }
  let(:update_day_of_week)      { "friday" }
  let(:update_start_time)       { "08:00" }
  let(:update_end_time)         { "12:00" }
  let(:update_start_date)       { nil }
  let(:update_end_date)         { nil }
  let(:update_priority)         { 3 }
  let(:update_is_active)        { true }

  let(:request_params) do
    {
      name:          update_name,
      price_per_hour: update_price,
      day_of_week:   update_day_of_week,
      start_time:    update_start_time,
      end_time:      update_end_time,
      start_date:    update_start_date,
      end_date:      update_end_date,
      priority:      update_priority,
      is_active:     update_is_active
    }
  end

  before do
    patch endpoint, params: request_params.to_json, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner with full valid params" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the pricing rules update response schema" do
      expect(response).to match_json_schema("pricing_rules/update_response")
    end

    it "persists all updated fields to the database" do
      pricing_rule.reload
      expect(pricing_rule.name).to eq(update_name)
      expect(pricing_rule.price_per_hour.to_f).to eq(update_price)
      expect(pricing_rule.day_of_week).to eq(update_day_of_week)
      expect(pricing_rule.priority).to eq(update_priority)
    end

    it "returns the updated values in the response body" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "name"          => update_name,
        "day_of_week"   => update_day_of_week,
        "priority"      => update_priority,
        "is_active"     => update_is_active
      )
    end

    it "returns the correct court_id and venue_id" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "court_id" => court.id,
        "venue_id" => venue.id
      )
    end

    it "returns a time_range derived from updated start and end times" do
      data = response.parsed_body["data"]
      expect(data["time_range"]).to be_a(String)
      expect(data["time_range"]).not_to eq("All day")
    end

    it "returns the humanized day_name for the updated day_of_week" do
      data = response.parsed_body["data"]
      expect(data["day_name"]).to eq("Friday")
    end
  end

  context "when authenticated as global admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "persists the updates" do
      expect(pricing_rule.reload.name).to eq(update_name)
    end

    it "matches the pricing rules update response schema" do
      expect(response).to match_json_schema("pricing_rules/update_response")
    end
  end

  context "when only a single field is updated (partial update)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params)  { { name: "Only Name Changed" } }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "updates only the provided field" do
      expect(pricing_rule.reload.name).to eq("Only Name Changed")
    end

    it "leaves other fields unchanged" do
      pricing_rule.reload
      expect(pricing_rule.price_per_hour.to_f).to eq(2500.0)
      expect(pricing_rule.day_of_week).to eq("monday")
      expect(pricing_rule.priority).to eq(2)
    end
  end

  context "when toggling is_active to false" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params)  { { is_active: false } }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "persists is_active as false" do
      expect(pricing_rule.reload.is_active).to be false
    end

    it "returns is_active false in response" do
      expect(response.parsed_body["data"]["is_active"]).to be false
    end
  end

  context "when updating day_of_week to weekends" do
    let(:request_headers)    { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_day_of_week) { "weekends" }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "persists day_of_week as weekends" do
      expect(pricing_rule.reload.day_of_week).to eq("weekends")
    end

    it "returns day_name as Weekends" do
      expect(response.parsed_body["data"]["day_name"]).to eq("Weekends")
    end
  end

  context "when updating priority to a higher value" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_priority) { 10 }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "persists the new priority" do
      expect(pricing_rule.reload.priority).to eq(10)
    end
  end

  context "when adding a date range to an existing rule" do
    let(:request_headers)    { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_start_date)  { "2026-06-01" }
    let(:update_end_date)    { "2026-08-31" }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "persists start_date and end_date" do
      pricing_rule.reload
      expect(pricing_rule.start_date.to_s).to eq("2026-06-01")
      expect(pricing_rule.end_date.to_s).to eq("2026-08-31")
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

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.name).to eq("Evening Peak")
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

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.name).to eq("Evening Peak")
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

  context "when authenticated as a customer (insufficient permissions)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.name).to eq("Evening Peak")
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when authenticated as receptionist (view-only permissions)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.name).to eq("Evening Peak")
    end
  end

  context "when authenticated as the owner of a different venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(other_owner_user)) }

    it "returns forbidden (403) status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.name).to eq("Evening Peak")
    end
  end

  # ==================================================
  # FAILURE PATHS — Resource Not Found
  # ==================================================

  context "when the pricing rule ID does not exist" do
    let(:request_headers)  { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:pricing_rule_id)  { 999_999 }

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

  # ==================================================
  # FAILURE PATHS — Validation Errors
  # ==================================================

  context "when name is set to blank" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:request_params)  { { name: "" } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.name).to eq("Evening Peak")
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when price_per_hour is set to zero" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_price)    { 0 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.price_per_hour.to_f).to eq(2500.0)
    end
  end

  context "when price_per_hour is set to a negative value" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_price)    { -500.0 }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.price_per_hour.to_f).to eq(2500.0)
    end
  end

  context "when day_of_week is an invalid string" do
    let(:request_headers)    { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_day_of_week) { "invalid_day" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.day_of_week).to eq("monday")
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when end_time is before start_time" do
    let(:request_headers)   { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_start_time) { "14:00" }
    let(:update_end_time)   { "10:00" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      pricing_rule.reload
      expect(pricing_rule.start_time.strftime("%H:%M")).to eq("18:00")
      expect(pricing_rule.end_time.strftime("%H:%M")).to eq("23:00")
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when end_time equals start_time" do
    let(:request_headers)   { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_start_time) { "10:00" }
    let(:update_end_time)   { "10:00" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.start_time.strftime("%H:%M")).to eq("18:00")
    end
  end

  context "when end_date is before start_date" do
    let(:request_headers)    { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:update_start_date)  { "2026-09-01" }
    let(:update_end_date)    { "2026-01-01" }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not update the pricing rule" do
      expect(pricing_rule.reload.start_date).to be_nil
    end
  end
end
