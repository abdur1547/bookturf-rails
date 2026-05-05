# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DELETE /api/v0/courts/:id", type: :request do
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

  # Operating hours for all 7 days so the venue is always "open" when the booking is created.
  # Required before existing_booking is created due to Booking#within_operating_hours validation.
  let!(:venue_operating_hours) do
    (0..6).map do |day|
      create(:venue_operating_hour,
             venue: venue,
             day_of_week: day,
             opens_at: "08:00",
             closes_at: "22:00",
             is_closed: false)
    end
  end

  let!(:court) { create(:court, venue: venue, court_type: court_type, name: "Court Alpha") }

  # Pre-created at outer level so they exist before the DELETE request fires.
  # Used by the "court has bookings" context to override court_id.
  let!(:court_with_bookings) { create(:court, venue: venue, court_type: court_type, name: "Court With Bookings") }
  let!(:existing_booking) { create(:booking, court: court_with_bookings, venue: venue) }

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:court_id) { court.id }
  let(:endpoint) { "/api/v0/courts/#{court_id}" }
  let(:request_headers) { headers }

  before do
    delete endpoint, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as the venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the courts delete response schema" do
      expect(response).to match_json_schema("courts/delete_response")
    end

    it "removes the court from the database" do
      expect(Court.exists?(court.id)).to be false
    end

    it "returns the success deletion message" do
      expect(response.parsed_body["data"]).to include("message" => "Court deleted successfully")
    end

    it "returns success: true in the response body" do
      expect(response.parsed_body).to include("success" => true)
    end
  end

  context "when authenticated as a global admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns ok (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "removes the court from the database" do
      expect(Court.exists?(court.id)).to be false
    end

    it "matches the courts delete response schema" do
      expect(response).to match_json_schema("courts/delete_response")
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

    it "does not delete the court" do
      expect(Court.exists?(court.id)).to be true
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

    it "does not delete the court" do
      expect(Court.exists?(court.id)).to be true
    end
  end

  context "when a malformed Authorization header is provided (missing Bearer prefix)" do
    let(:request_headers) { headers.merge("Authorization" => "NotBearer sometoken") }

    it "returns unauthorized (401) status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "does not delete the court" do
      expect(Court.exists?(court.id)).to be true
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

    it "does not delete the court" do
      expect(Court.exists?(court.id)).to be true
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

    it "does not delete the court" do
      expect(Court.exists?(court.id)).to be true
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  # ==================================================
  # FAILURE PATHS — Resource Not Found
  # ==================================================

  context "when the court does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_id) { 999_999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  # ==================================================
  # FAILURE PATHS — Cannot Delete with Dependencies
  # ==================================================

  context "when the court has existing bookings" do
    # court_with_bookings and existing_booking are created at the outer describe level
    # (via let!) so they exist before the before-block DELETE request fires.
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:court_id) { court_with_bookings.id }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not delete the court" do
      expect(Court.exists?(court_with_bookings.id)).to be true
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end
end
