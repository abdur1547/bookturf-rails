# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/courts", type: :request do
  # ==================================================
  # SHARED TEST DATA SETUP
  # ==================================================
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user) { create(:user, email: "owner@example.com") }
  let(:admin_user) { create(:user, :super_admin, email: "admin@example.com") }
  let(:customer_user) { create(:user, email: "customer@example.com") }

  let!(:court_type_badminton) { create(:court_type, name: "Badminton", slug: "badminton") }
  let!(:court_type_cricket) { create(:court_type, name: "Cricket", slug: "cricket") }

  let!(:venue_karachi) do
    create(:venue, name: "Alpha Arena", city: "Karachi", is_active: true, owner: owner_user)
  end
  let!(:venue_lahore) do
    create(:venue, name: "Beta Complex", city: "Lahore", is_active: true, owner: admin_user)
  end

  let!(:court_active_1) do
    create(:court,
           venue: venue_karachi,
           court_type: court_type_badminton,
           name: "Court Alpha",
           is_active: true)
  end
  let!(:court_active_2) do
    create(:court,
           venue: venue_lahore,
           court_type: court_type_cricket,
           name: "Court Beta",
           is_active: true)
  end
  let!(:court_inactive) do
    create(:court,
           venue: venue_karachi,
           court_type: court_type_badminton,
           name: "Court Gamma",
           is_active: false)
  end

  # ==================================================
  # ENDPOINT AND PARAMETER SETUP
  # ==================================================
  let(:endpoint) { "/api/v0/courts" }
  let(:query_params) { {} }
  let(:request_headers) { headers }

  before do
    params_string = query_params.present? ? "?#{query_params.to_query}" : ""
    get "#{endpoint}#{params_string}", headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS — Public access
  # ==================================================

  context "when not authenticated (public access)" do
    let(:request_headers) { headers }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all courts with no default is_active filter" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
    end

    it "matches the courts index response schema" do
      expect(response).to match_json_schema("courts/index_response")
    end

    it "embeds the correct court_type for each court" do
      data = response.parsed_body["data"]
      alpha_court = data.find { |c| c["name"] == "Court Alpha" }
      expect(alpha_court["court_type"]["name"]).to eq("Badminton")
    end

    it "embeds the correct venue for each court" do
      data = response.parsed_body["data"]
      alpha_court = data.find { |c| c["name"] == "Court Alpha" }
      expect(alpha_court["venue"]["name"]).to eq("Alpha Arena")
    end

    # --------------------------------------------------
    # Filtering
    # --------------------------------------------------

    context "with venue_id filter" do
      let(:query_params) { { venue_id: venue_karachi.id } }

      it "returns only courts belonging to that venue" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
        expect(data).to all(include("venue_id" => venue_karachi.id))
      end

      it "excludes courts from other venues" do
        data = response.parsed_body["data"]
        expect(data.none? { |c| c["venue_id"] == venue_lahore.id }).to be true
      end
    end

    context "with court_type_id filter" do
      let(:query_params) { { court_type_id: court_type_badminton.id } }

      it "returns only courts of that type" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
        expect(data).to all(include("court_type_id" => court_type_badminton.id))
      end

      it "excludes courts of other types" do
        data = response.parsed_body["data"]
        expect(data.none? { |c| c["court_type_id"] == court_type_cricket.id }).to be true
      end
    end

    context "with city filter" do
      let(:query_params) { { city: "Karachi" } }

      it "returns only courts at venues in that city" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
        expect(data).to all(include("city" => "Karachi"))
      end

      it "excludes courts at venues in other cities" do
        data = response.parsed_body["data"]
        expect(data.none? { |c| c["city"] == "Lahore" }).to be true
      end
    end

    context "with is_active=true filter" do
      let(:query_params) { { is_active: true } }

      it "returns only active courts" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
        expect(data).to all(include("is_active" => true))
      end

      it "excludes inactive courts" do
        data = response.parsed_body["data"]
        expect(data.none? { |c| c["is_active"] == false }).to be true
      end
    end

    context "with is_active=false filter" do
      let(:query_params) { { is_active: false } }

      it "returns only inactive courts" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("is_active" => false))
      end

      it "excludes active courts" do
        data = response.parsed_body["data"]
        expect(data.none? { |c| c["is_active"] == true }).to be true
      end
    end

    context "with search matching court name" do
      let(:query_params) { { search: "Court Alpha" } }

      it "returns the matching court" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first["name"]).to eq("Court Alpha")
      end
    end

    context "with search matching court description" do
      let(:query_params) { { search: "Premium indoor" } }

      it "returns courts matching the description term" do
        data = response.parsed_body["data"]
        expect(data.length).to be >= 1
      end
    end

    context "with search matching venue name" do
      let(:query_params) { { search: "Beta Complex" } }

      it "returns courts belonging to the matching venue" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first["venue_name"]).to eq("Beta Complex")
      end
    end

    context "with search that matches nothing" do
      let(:query_params) { { search: "NonExistentCourt12345" } }

      it "returns an empty array" do
        data = response.parsed_body["data"]
        expect(data).to eq([])
      end

      it "returns success (200) status" do
        expect(response).to have_http_status(:ok)
      end
    end

    # --------------------------------------------------
    # Sorting
    # --------------------------------------------------

    context "with sort=name and order=asc" do
      let(:query_params) { { sort: "name", order: "asc" } }

      it "returns courts sorted by name ascending" do
        data = response.parsed_body["data"]
        names = data.map { |c| c["name"] }
        expect(names).to eq(names.sort)
      end
    end

    context "with sort=name and order=desc" do
      let(:query_params) { { sort: "name", order: "desc" } }

      it "returns courts sorted by name descending" do
        data = response.parsed_body["data"]
        names = data.map { |c| c["name"] }
        expect(names).to eq(names.sort.reverse)
      end
    end

    context "with sort=created_at and order=asc" do
      let(:query_params) { { sort: "created_at", order: "asc" } }

      it "returns success (200) status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns courts sorted by creation date ascending" do
        data = response.parsed_body["data"]
        timestamps = data.map { |c| c["created_at"] }
        expect(timestamps).to eq(timestamps.sort)
      end
    end

    # --------------------------------------------------
    # Pagination
    # --------------------------------------------------

    context "with page=1 and per_page=2" do
      let(:query_params) { { page: 1, per_page: 2 } }

      it "returns exactly 2 courts" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
      end
    end

    context "with page=2 and per_page=2" do
      let(:query_params) { { page: 2, per_page: 2 } }

      it "returns the remaining 1 court on the second page" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
      end
    end

    context "with per_page exceeding the maximum (1000 requested, 100 allowed)" do
      let(:query_params) { { per_page: 1000 } }

      it "returns success (200) status" do
        expect(response).to have_http_status(:ok)
      end

      it "caps results at a maximum of 100" do
        data = response.parsed_body["data"]
        expect(data.length).to be <= 100
      end
    end

    # --------------------------------------------------
    # Combined filters
    # --------------------------------------------------

    context "with combined venue_id and is_active=true filters" do
      let(:query_params) { { venue_id: venue_karachi.id, is_active: true } }

      it "returns only the single active court in that venue" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first).to include(
          "venue_id" => venue_karachi.id,
          "is_active" => true
        )
      end
    end

    context "with combined court_type_id and is_active=true filters" do
      let(:query_params) { { court_type_id: court_type_cricket.id, is_active: true } }

      it "returns only the active cricket court" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first).to include(
          "court_type_id" => court_type_cricket.id,
          "is_active" => true
        )
      end
    end

    # --------------------------------------------------
    # Empty results
    # --------------------------------------------------

    context "when no courts match the venue_id filter" do
      let(:query_params) { { venue_id: 999_999 } }

      it "returns an empty data array" do
        data = response.parsed_body["data"]
        expect(data).to eq([])
      end

      it "returns success (200) status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the index response schema" do
        expect(response).to match_json_schema("courts/index_response")
      end
    end
  end

  # ==================================================
  # SUCCESS PATHS — Authenticated users
  # ==================================================

  context "when authenticated as owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all courts" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("courts/index_response")
    end
  end

  context "when authenticated as admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all courts" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
    end
  end

  context "when authenticated as customer" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all courts (public endpoint, no role restriction)" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
    end
  end

  # ==================================================
  # EDGE CASES — Invalid parameters
  # ==================================================

  context "with an invalid sort field" do
    let(:query_params) { { sort: "invalid_column" } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns an error response" do
      expect(response.parsed_body).to include("success" => false)
    end

    it "matches the error response schema" do
      expect(response).to match_json_schema("error_response")
    end
  end

  context "with an invalid order direction" do
    let(:query_params) { { order: "random" } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns an error response" do
      expect(response.parsed_body).to include("success" => false)
    end
  end

  context "with a negative page number (contract requires gt: 0)" do
    let(:query_params) { { page: -1 } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "with per_page of zero (contract requires gt: 0)" do
    let(:query_params) { { per_page: 0 } }

    it "returns unprocessable entity (422) status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "with an invalid Bearer token (public endpoint ignores auth)" do
    let(:request_headers) { headers.merge("Authorization" => "Bearer invalid.token.xyz") }

    it "returns success (200) status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all courts" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(3)
    end
  end
end
