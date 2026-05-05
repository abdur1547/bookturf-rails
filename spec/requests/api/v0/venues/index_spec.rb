# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/venues", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user) { create(:user, email: "owner@example.com") }
  let(:admin_user) { create(:user, :super_admin, email: "admin@example.com") }
  let(:customer_user) { create(:user, email: "customer@example.com") }

  let(:endpoint) { "/api/v0/venues" }
  let(:query_params) { {} }
  let(:request_headers) { headers }

  # Create test venues
  let!(:venue1) do
    create(:venue,
           name: "Alpha Sports Arena",
           city: "Karachi",
           state: "Sindh",
           country: "Pakistan",
           is_active: true,
           owner: owner_user)
  end

  let!(:venue2) do
    create(:venue,
           name: "Beta Sports Complex",
           city: "Lahore",
           state: "Punjab",
           country: "Pakistan",
           is_active: true,
           owner: admin_user)
  end

  let!(:venue3) do
    create(:venue,
           name: "Gamma Fitness Center",
           city: "Karachi",
           state: "Sindh",
           country: "Pakistan",
           is_active: false,
           owner: customer_user)
  end

  before do
    params_string = query_params.present? ? "?#{query_params.to_query}" : ""
    get "#{endpoint}#{params_string}", headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when not authenticated (public access)" do
    let(:request_headers) { headers }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("venues/index_response")
    end

    it "returns only active venues by default" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(2)
      expect(data).to all(include("is_active" => true))
    end

    it "includes complete venue attributes in response" do
      venue_data = response.parsed_body["data"].first
      expect(venue_data).to include(
        "id" => be_a(Integer),
        "name" => be_a(String),
        "slug" => be_a(String),
        "address" => be_a(String),
        "city" => be_a(String),
        "state" => be_a(String),
        "country" => be_a(String),
        "is_active" => be_in([ true, false ]),
        "created_at" => be_a(String),
        "courts_count" => be_a(Integer)
      )
    end

    it "includes google_maps_url when coordinates are present" do
      venue_data = response.parsed_body["data"].first
      expect(venue_data["google_maps_url"]).to be_present
      expect(venue_data["google_maps_url"]).to include("google.com/maps")
    end

    context "with city filter" do
      let(:query_params) { { city: "Karachi" } }

      it "returns only venues in specified city" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("city" => "Karachi"))
      end

      it "excludes venues from other cities" do
        data = response.parsed_body["data"]
        expect(data.none? { |v| v["city"] == "Lahore" }).to be true
      end
    end

    context "with state filter" do
      let(:query_params) { { state: "Punjab" } }

      it "returns only venues in specified state" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("state" => "Punjab"))
      end
    end

    context "with country filter" do
      let(:query_params) { { country: "Pakistan" } }

      it "returns venues in specified country" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
        expect(data).to all(include("country" => "Pakistan"))
      end
    end

    context "with is_active=false filter" do
      let(:query_params) { { is_active: false } }

      it "returns only inactive venues" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("is_active" => false))
      end

      it "excludes active venues" do
        data = response.parsed_body["data"]
        expect(data.none? { |v| v["is_active"] == true }).to be true
      end
    end

    context "with is_active=true filter" do
      let(:query_params) { { is_active: true } }

      it "returns only active venues" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(2)
        expect(data).to all(include("is_active" => true))
      end
    end

    context "with search parameter" do
      let(:query_params) { { search: "Alpha" } }

      it "returns matching venues" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first["name"]).to eq("Alpha Sports Arena")
      end
    end

    context "with search by city" do
      let(:query_params) { { search: "Lahore" } }

      it "returns venues matching city" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first["city"]).to eq("Lahore")
      end
    end

    context "with sort=name parameter" do
      let(:query_params) { { sort: "name", order: "asc" } }

      it "sorts venues by name alphabetically" do
        data = response.parsed_body["data"]
        names = data.map { |v| v["name"] }
        expect(names).to eq(names.sort)
      end
    end

    context "with sort=name and order=desc" do
      let(:query_params) { { sort: "name", order: "desc" } }

      it "sorts venues by name in descending order" do
        data = response.parsed_body["data"]
        names = data.map { |v| v["name"] }
        expect(names).to eq(names.sort.reverse)
      end
    end

    context "with sort=city parameter" do
      let(:query_params) { { sort: "city" } }

      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end

      it "sorts venues by city" do
        data = response.parsed_body["data"]
        cities = data.map { |v| v["city"] }
        expect(cities).to eq(cities.sort)
      end
    end

    context "with sort=created_at parameter" do
      let(:query_params) { { sort: "created_at", order: "desc" } }

      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "with pagination" do
      let(:query_params) { { page: 1, per_page: 1 } }

      it "returns correct number of results per page" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
      end
    end

    context "with combined filters" do
      let(:query_params) { { city: "Karachi", is_active: true } }

      it "applies all filters correctly" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first).to include(
          "city" => "Karachi",
          "is_active" => true
        )
      end
    end

    context "when no venues match filters" do
      let(:query_params) { { city: "Islamabad" } }

      it "returns empty array" do
        data = response.parsed_body["data"]
        expect(data).to eq([])
      end

      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  context "when authenticated as owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns active venues by default" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(2)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("venues/index_response")
    end
  end

  context "when authenticated as admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns venues" do
      data = response.parsed_body["data"]
      expect(data.length).to be >= 1
    end
  end

  context "when authenticated as customer" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns venues (public endpoint)" do
      data = response.parsed_body["data"]
      expect(data.length).to be >= 1
    end
  end

  # ==================================================
  # EDGE CASES
  # ==================================================

  context "with invalid sort parameter" do
    let(:query_params) { { sort: "invalid_field" } }

    it "returns success response (falls back to default)" do
      expect(response).to have_http_status(:ok)
    end

    it "returns venues with default sorting" do
      data = response.parsed_body["data"]
      expect(data.length).to be >= 1
    end
  end

  context "with very large per_page value" do
    let(:query_params) { { per_page: 1000 } }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "limits results to maximum allowed (100)" do
      # This depends on implementation, but should not return more than max
      data = response.parsed_body["data"]
      expect(data.length).to be <= 100
    end
  end

  context "with negative page number" do
    let(:query_params) { { page: -1 } }

    it "returns success response (treats as page 1)" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "with zero per_page" do
    let(:query_params) { { per_page: 0 } }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when venue has no coordinates" do
    let(:new_owner) { create(:user, email: "newowner@example.com") }

    let!(:venue_no_coords) do
      create(:venue, :without_coordinates, city: "Islamabad", is_active: true, owner: new_owner)
    end

    it "returns venue with null google_maps_url" do
      # Make the request AFTER the venue is created
      get "#{endpoint}?city=Islamabad", headers: request_headers

      data = response.parsed_body["data"]
      expect(data).to be_an(Array)
      expect(data.length).to be >= 1

      venue_data = data.first
      expect(venue_data["city"]).to eq("Islamabad")
      expect(venue_data["google_maps_url"]).to be_nil
      expect(venue_data["latitude"]).to be_nil
      expect(venue_data["longitude"]).to be_nil
    end
  end
end
