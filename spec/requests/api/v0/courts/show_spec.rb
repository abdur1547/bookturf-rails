# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/courts/:id", type: :request do
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

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    customer_user.assign_role(customer_role)
  end

  let!(:court_type) { create(:court_type, name: "Badminton", slug: "badminton") }
  let!(:venue) do
    create(:venue, name: "Alpha Arena", city: "Karachi", is_active: true, owner: owner_user)
  end
  let!(:court) do
    create(:court,
           venue: venue,
           court_type: court_type,
           name: "Court Alpha",
           description: "A premium indoor badminton court",
           is_active: true)
  end

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:court_id) { court.id }
  let(:endpoint) { "/api/v0/courts/#{court_id}" }
  let(:request_headers) { headers }

  before do
    get endpoint, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when not authenticated (public access)" do
    let(:request_headers) { headers }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns success: true" do
      expect(response.parsed_body["success"]).to be true
    end

    it "matches the show response schema" do
      expect(response).to match_json_schema("courts/show_response")
    end

    it "returns the correct court by id" do
      data = response.parsed_body["data"]
      expect(data["id"]).to eq(court.id)
    end

    it "includes all expected court attributes" do
      data = response.parsed_body["data"]
      expect(data).to include(
        "id" => court.id,
        "name" => "Court Alpha",
        "description" => "A premium indoor badminton court",
        "court_type_id" => court_type.id,
        "venue_id" => venue.id,
        "is_active" => true,
        "created_at" => be_a(String),
        "updated_at" => be_a(String)
      )
    end

    it "includes court_type_name derived from court type" do
      data = response.parsed_body["data"]
      expect(data["court_type_name"]).to eq("Badminton")
    end

    it "includes venue_name derived from venue" do
      data = response.parsed_body["data"]
      expect(data["venue_name"]).to eq("Alpha Arena")
    end

    it "includes city derived from venue" do
      data = response.parsed_body["data"]
      expect(data["city"]).to eq("Karachi")
    end

    it "includes price_range with min and max keys" do
      data = response.parsed_body["data"]
      expect(data["price_range"]).to include("min", "max")
    end

    it "includes price_range with zero values when no pricing rules exist" do
      data = response.parsed_body["data"]
      expect(data["price_range"]["min"]).to eq(0.0)
      expect(data["price_range"]["max"]).to eq(0.0)
    end

    it "includes images as an array" do
      data = response.parsed_body["data"]
      expect(data["images"]).to be_an(Array)
    end

    it "includes pricing_rules as an empty array when none exist" do
      data = response.parsed_body["data"]
      expect(data["pricing_rules"]).to be_an(Array)
      expect(data["pricing_rules"]).to be_empty
    end

    it "includes embedded court_type with minimal fields" do
      data = response.parsed_body["data"]
      expect(data["court_type"]).to include(
        "id" => court_type.id,
        "name" => "Badminton",
        "slug" => "badminton"
      )
    end

    it "includes embedded venue with minimal fields" do
      data = response.parsed_body["data"]
      expect(data["venue"]).to include(
        "id" => venue.id,
        "name" => "Alpha Arena",
        "city" => "Karachi"
      )
    end
  end

  context "when court is inactive" do
    let!(:inactive_court) do
      create(:court, venue: venue, court_type: court_type, name: "Inactive Court", is_active: false)
    end
    let(:court_id) { inactive_court.id }

    it "returns success (200) status — public endpoint returns inactive courts" do
      expect(response).to have_http_status(:ok)
    end

    it "shows is_active as false in the response" do
      data = response.parsed_body["data"]
      expect(data["is_active"]).to be false
    end

    it "matches the show response schema" do
      expect(response).to match_json_schema("courts/show_response")
    end
  end

  context "when authenticated as owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the show response schema" do
      expect(response).to match_json_schema("courts/show_response")
    end

    it "returns the correct court" do
      data = response.parsed_body["data"]
      expect(data["id"]).to eq(court.id)
    end
  end

  context "when authenticated as admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the show response schema" do
      expect(response).to match_json_schema("courts/show_response")
    end
  end

  context "when authenticated as customer" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns the court data" do
      data = response.parsed_body["data"]
      expect(data["id"]).to eq(court.id)
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when court does not exist" do
    let(:court_id) { 999999 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns success: false" do
      expect(response.parsed_body["success"]).to be false
    end

    it "returns a not found error message" do
      expect(response.parsed_body["errors"]).to eq([ "The requested resource does not exist" ])
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when id is non-numeric" do
    let(:court_id) { "invalid-id" }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns success: false" do
      expect(response.parsed_body["success"]).to be false
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "when court id is zero" do
    let(:court_id) { 0 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns success: false" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when court id is negative" do
    let(:court_id) { -1 }

    it "returns not found (404) status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns success: false" do
      expect(response.parsed_body["success"]).to be false
    end
  end
end
