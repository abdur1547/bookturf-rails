# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v0/venues/search", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user)    { create(:user, email: "owner@example.com") }
  let(:other_user)    { create(:user, email: "other@example.com") }
  let(:customer_user) { create(:user, email: "customer@example.com") }

  let(:endpoint)        { "/api/v0/venues/search" }
  let(:query_params)    { {} }
  let(:request_headers) { headers }

  let!(:venue_karachi_active) do
    create(:venue,
           name: "Alpha Sports Arena",
           city: "Karachi",
           state: "Sindh",
           country: "Pakistan",
           is_active: true,
           owner: owner_user)
  end

  let!(:venue_lahore_active) do
    create(:venue,
           name: "Beta Sports Complex",
           city: "Lahore",
           state: "Punjab",
           country: "Pakistan",
           is_active: true,
           owner: other_user)
  end

  let!(:venue_inactive) do
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
  # PUBLIC ACCESS — no authentication required
  # ==================================================

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the search response schema" do
      expect(response).to match_json_schema("venues/search_response")
    end

    it "returns only active venues by default" do
      data = response.parsed_body["data"]
      expect(data).to all(include("is_active" => true))
    end

    it "does not return inactive venues by default" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).not_to include("Gamma Fitness Center")
    end

    it "returns venues from all owners" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).to include("Alpha Sports Arena", "Beta Sports Complex")
    end
  end

  # ==================================================
  # AUTHENTICATED ACCESS — same results as public
  # ==================================================

  context "when authenticated as any user" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the search response schema" do
      expect(response).to match_json_schema("venues/search_response")
    end

    it "returns active venues from all owners, not just their own" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).to include("Alpha Sports Arena", "Beta Sports Complex")
    end
  end

  # ==================================================
  # RESPONSE STRUCTURE
  # ==================================================

  context "response attributes" do
    it "includes complete venue attributes" do
      venue_data = response.parsed_body["data"].first
      expect(venue_data).to include(
        "id"           => be_a(Integer),
        "name"         => be_a(String),
        "slug"         => be_a(String),
        "address"      => be_a(String),
        "city"         => be_a(String),
        "state"        => be_a(String),
        "country"      => be_a(String),
        "is_active"    => be_in([ true, false ]),
        "created_at"   => be_a(String),
        "courts_count" => be_a(Integer)
      )
    end

    it "includes google_maps_url when coordinates are present" do
      venue_data = response.parsed_body["data"].first
      expect(venue_data["google_maps_url"]).to be_present
      expect(venue_data["google_maps_url"]).to include("google.com/maps")
    end
  end

  context "when venue has no coordinates" do
    let(:no_coords_owner) { create(:user, email: "nocoordsowner@example.com") }
    let!(:venue_no_coords) do
      create(:venue, :without_coordinates, name: "No Coords Venue", city: "Islamabad", is_active: true, owner: no_coords_owner)
    end

    # Re-run the request after venue_no_coords is created by let!
    before do
      get "#{endpoint}?city=Islamabad", headers: request_headers
    end

    it "returns null google_maps_url" do
      data = response.parsed_body["data"]
      venue_data = data.find { |v| v["name"] == "No Coords Venue" }
      expect(venue_data["google_maps_url"]).to be_nil
      expect(venue_data["latitude"]).to be_nil
      expect(venue_data["longitude"]).to be_nil
    end
  end

  # ==================================================
  # DEFAULT BEHAVIOUR — active filter
  # ==================================================

  context "with default params (no is_active filter)" do
    it "returns only active venues" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(2)
      expect(data).to all(include("is_active" => true))
    end
  end

  # ==================================================
  # is_active FILTER
  # ==================================================

  context "with is_active=true filter" do
    let(:query_params) { { is_active: true } }

    it "returns only active venues" do
      data = response.parsed_body["data"]
      expect(data).to all(include("is_active" => true))
    end

    it "does not include inactive venues" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).not_to include("Gamma Fitness Center")
    end
  end

  context "with is_active=false filter" do
    let(:query_params) { { is_active: false } }

    it "returns only inactive venues" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data).to all(include("is_active" => false))
    end

    it "returns the expected inactive venue" do
      data = response.parsed_body["data"]
      expect(data.first["name"]).to eq("Gamma Fitness Center")
    end
  end

  # ==================================================
  # CITY FILTER
  # ==================================================

  context "with city filter" do
    let(:query_params) { { city: "Karachi" } }

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only active venues in the specified city" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data).to all(include("city" => "Karachi"))
    end

    it "excludes venues from other cities" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).not_to include("Beta Sports Complex")
    end
  end

  context "with city filter that has no matches" do
    let(:query_params) { { city: "Multan" } }

    it "returns empty array" do
      expect(response.parsed_body["data"]).to eq([])
    end

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end

  # ==================================================
  # STATE FILTER
  # ==================================================

  context "with state filter" do
    let(:query_params) { { state: "Sindh" } }

    it "returns only active venues in specified state" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data).to all(include("state" => "Sindh"))
    end
  end

  context "with state filter that has no active matches" do
    let(:query_params) { { state: "Balochistan" } }

    it "returns empty array" do
      expect(response.parsed_body["data"]).to eq([])
    end
  end

  # ==================================================
  # COUNTRY FILTER
  # ==================================================

  context "with country filter" do
    let(:query_params) { { country: "Pakistan" } }

    it "returns venues in specified country" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(2)
      expect(data).to all(include("country" => "Pakistan"))
    end
  end

  # ==================================================
  # COMBINED FILTERS
  # ==================================================

  context "with city and is_active=false combined" do
    let(:query_params) { { city: "Karachi", is_active: false } }

    it "returns only inactive venues in Karachi" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first).to include("city" => "Karachi", "is_active" => false)
    end
  end

  context "with city and country combined" do
    let(:query_params) { { city: "Lahore", country: "Pakistan" } }

    it "applies both filters correctly" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["name"]).to eq("Beta Sports Complex")
    end
  end

  # ==================================================
  # FULL-TEXT SEARCH
  # ==================================================

  context "with search matching venue name" do
    let(:query_params) { { search: "Alpha" } }

    it "returns matching venue" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["name"]).to eq("Alpha Sports Arena")
    end
  end

  context "with search matching city" do
    let(:query_params) { { search: "Lahore" } }

    it "returns venues whose city matches" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["city"]).to eq("Lahore")
    end
  end

  context "with search matching description" do
    let(:desc_owner) { create(:user, email: "descowner@example.com") }
    let!(:venue_with_desc) do
      create(:venue,
             name: "Delta Courts",
             description: "tennis paradise",
             city: "Islamabad",
             is_active: true,
             owner: desc_owner)
    end

    # Re-run the request after venue_with_desc is created by let!
    before do
      get "#{endpoint}?search=tennis+paradise", headers: request_headers
    end

    it "returns venue whose description matches" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["name"]).to eq("Delta Courts")
    end
  end

  context "with search that matches no venues" do
    let(:query_params) { { search: "zzznomatchzzz" } }

    it "returns empty array" do
      expect(response.parsed_body["data"]).to eq([])
    end

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "with case-insensitive search" do
    let(:query_params) { { search: "alpha sports" } }

    it "matches regardless of case" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["name"]).to eq("Alpha Sports Arena")
    end
  end

  # ==================================================
  # SORTING
  # ==================================================

  context "with sort_by=name and sort_direction=asc" do
    let(:query_params) { { sort_by: "name", sort_direction: "asc" } }

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end

    it "returns venues sorted by name ascending" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).to eq(names.sort)
    end
  end

  context "with sort_by=name and sort_direction=desc" do
    let(:query_params) { { sort_by: "name", sort_direction: "desc" } }

    it "returns venues sorted by name descending" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).to eq(names.sort.reverse)
    end
  end

  context "with sort_by=city" do
    let(:query_params) { { sort_by: "city" } }

    it "returns venues sorted by city ascending (default direction)" do
      cities = response.parsed_body["data"].map { |v| v["city"] }
      expect(cities).to eq(cities.sort)
    end
  end

  context "with sort_by=created_at" do
    let(:query_params) { { sort_by: "created_at", sort_direction: "desc" } }

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "with invalid sort_by parameter" do
    let(:query_params) { { sort_by: "not_a_column" } }

    it "returns unprocessable entity (contract validation rejects unknown column)" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context "with invalid sort_direction parameter" do
    let(:query_params) { { sort_direction: "sideways" } }

    it "returns unprocessable entity" do
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  # ==================================================
  # PAGINATION
  # ==================================================

  context "with page=1 and per_page=1" do
    let(:query_params) { { page: 1, per_page: 1 } }

    it "returns exactly 1 result" do
      expect(response.parsed_body["data"].length).to eq(1)
    end

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "with page=2 and per_page=1" do
    let(:query_params) { { page: 2, per_page: 1 } }

    it "returns the second page of results" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
    end
  end

  context "with per_page larger than maximum (100)" do
    let(:query_params) { { per_page: 500 } }

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end

    it "limits results to 100 at most" do
      expect(response.parsed_body["data"].length).to be <= 100
    end
  end

  context "with negative page number" do
    let(:query_params) { { page: -1 } }

    it "returns success (treated as page 1)" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "with zero per_page" do
    let(:query_params) { { per_page: 0 } }

    it "returns success (uses default minimum)" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "with page beyond available results" do
    let(:query_params) { { page: 999, per_page: 10 } }

    it "returns empty array" do
      expect(response.parsed_body["data"]).to eq([])
    end

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end
  end
end
