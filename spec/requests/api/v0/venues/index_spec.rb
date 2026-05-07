# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "GET /api/v0/venues", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  let(:owner_user)       { create(:user, email: "owner@example.com") }
  let(:admin_user)       { create(:user, :super_admin, email: "admin@example.com") }
  let(:customer_user)    { create(:user, email: "customer@example.com") }
  let(:staff_user)       { create(:user, email: "staff@example.com") }
  let(:unaffiliated_user) { create(:user, email: "unaffiliated@example.com") }

  let(:endpoint)        { "/api/v0/venues" }
  let(:query_params)    { {} }
  let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

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
  # AUTHENTICATION REQUIRED
  # ==================================================

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized" do
      expect(response).to have_http_status(:unauthorized)
    end
  end

  # ==================================================
  # OWNER ACCESS — sees only their own venues
  # ==================================================

  context "when authenticated as venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("venues/index_response")
    end

    it "returns only their own active venues" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["name"]).to eq("Alpha Sports Arena")
    end

    it "does not return venues owned by other users" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).not_to include("Beta Sports Complex", "Gamma Fitness Center")
    end

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

    context "with city filter" do
      let(:query_params) { { city: "Karachi" } }

      it "returns only venues in specified city" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("city" => "Karachi"))
      end
    end

    context "with city filter that has no matches in user's venues" do
      let(:query_params) { { city: "Islamabad" } }

      it "returns empty array" do
        expect(response.parsed_body["data"]).to eq([])
      end

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "with state filter" do
      let(:query_params) { { state: "Sindh" } }

      it "returns only venues in specified state" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("state" => "Sindh"))
      end
    end

    context "with country filter" do
      let(:query_params) { { country: "Pakistan" } }

      it "returns venues in specified country" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("country" => "Pakistan"))
      end
    end

    context "with is_active=false filter" do
      let(:query_params) { { is_active: false } }

      it "returns empty list (owner has no inactive venues)" do
        expect(response.parsed_body["data"]).to eq([])
      end
    end

    context "with is_active=true filter" do
      let(:query_params) { { is_active: true } }

      it "returns their active venues" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data).to all(include("is_active" => true))
      end
    end

    context "with search matching their venue name" do
      let(:query_params) { { search: "Alpha" } }

      it "returns matching venue" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first["name"]).to eq("Alpha Sports Arena")
      end
    end

    context "with search matching another user's venue" do
      let(:query_params) { { search: "Beta" } }

      it "returns empty (other users' venues not visible)" do
        expect(response.parsed_body["data"]).to eq([])
      end
    end

    context "with sort_by=name and sort_direction=asc" do
      let(:query_params) { { sort_by: "name", sort_direction: "asc" } }

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "with sort_by=created_at and sort_direction=desc" do
      let(:query_params) { { sort_by: "created_at", sort_direction: "desc" } }

      it "returns success" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "with invalid sort_by parameter" do
      let(:query_params) { { sort_by: "invalid_field" } }

      it "returns unprocessable entity (contract validation rejects unknown column)" do
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with pagination" do
      let(:query_params) { { page: 1, per_page: 1 } }

      it "returns correct number of results per page" do
        expect(response.parsed_body["data"].length).to eq(1)
      end
    end

    context "with very large per_page value" do
      let(:query_params) { { per_page: 1000 } }

      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end

      it "limits results to maximum allowed (100)" do
        expect(response.parsed_body["data"].length).to be <= 100
      end
    end

    context "with negative page number" do
      let(:query_params) { { page: -1 } }

      it "returns success (treats as page 1)" do
        expect(response).to have_http_status(:ok)
      end
    end

    context "with zero per_page" do
      let(:query_params) { { per_page: 0 } }

      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ==================================================
  # STAFF MEMBER ON MULTIPLE VENUES — sorting and filtering across venues
  # (MVP restricts one venue per owner, so staff is used for multi-venue tests)
  # ==================================================

  context "when staff member has read permission on multiple venues" do
    let(:second_owner) { create(:user, email: "second_owner@example.com") }
    let!(:venue4) do
      create(:venue,
             name: "Delta Arena",
             city: "Islamabad",
             state: "Islamabad Capital Territory",
             country: "Pakistan",
             is_active: true,
             owner: second_owner)
    end
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    before do
      permission = create(:permission, resource: "venues", action: "read")

      role1 = create(:role, venue: venue1)
      create(:role_permission, role: role1, permission: permission)
      create(:venue_membership, user: staff_user, venue: venue1, role: role1)

      role4 = create(:role, venue: venue4)
      create(:role_permission, role: role4, permission: permission)
      create(:venue_membership, user: staff_user, venue: venue4, role: role4)

      params_string = query_params.present? ? "?#{query_params.to_query}" : ""
      get "#{endpoint}#{params_string}", headers: request_headers
    end

    it "returns success" do
      expect(response).to have_http_status(:ok)
    end

    it "returns all venues they are staff of" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(2)
    end

    context "with sort_by=name and sort_direction=asc" do
      let(:query_params) { { sort_by: "name", sort_direction: "asc" } }

      it "sorts venues by name alphabetically" do
        data = response.parsed_body["data"]
        names = data.map { |v| v["name"] }
        expect(names).to eq(names.sort)
      end
    end

    context "with sort_by=name and sort_direction=desc" do
      let(:query_params) { { sort_by: "name", sort_direction: "desc" } }

      it "sorts venues by name in descending order" do
        data = response.parsed_body["data"]
        names = data.map { |v| v["name"] }
        expect(names).to eq(names.sort.reverse)
      end
    end

    context "with sort_by=city" do
      let(:query_params) { { sort_by: "city" } }

      it "sorts venues by city" do
        data = response.parsed_body["data"]
        cities = data.map { |v| v["city"] }
        expect(cities).to eq(cities.sort)
      end
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
        expect(data.none? { |v| v["city"] == "Islamabad" }).to be true
      end
    end

    context "with combined city and is_active filters" do
      let(:query_params) { { city: "Islamabad", is_active: true } }

      it "applies all filters correctly" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first).to include("city" => "Islamabad", "is_active" => true)
      end
    end

    context "when no venues match filters" do
      let(:query_params) { { city: "Multan" } }

      it "returns empty array" do
        expect(response.parsed_body["data"]).to eq([])
      end

      it "returns success response" do
        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ==================================================
  # VENUE WITH NO COORDINATES
  # ==================================================

  context "when venue has no coordinates" do
    let(:new_owner) { create(:user, email: "newowner@example.com") }
    let!(:venue_no_coords) do
      create(:venue, :without_coordinates, city: "Islamabad", is_active: true, owner: new_owner)
    end

    it "returns venue with null google_maps_url" do
      get "#{endpoint}?city=Islamabad", headers: headers.merge("Authorization" => auth_token_for(new_owner))

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

  # ==================================================
  # OWNER WITH ONLY AN INACTIVE VENUE
  # ==================================================

  context "when authenticated as owner of only an inactive venue" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns empty list by default (inactive venue excluded by default active filter)" do
      expect(response.parsed_body["data"]).to eq([])
    end

    context "when filtering by is_active=false" do
      let(:query_params) { { is_active: false } }

      it "returns their inactive venue" do
        data = response.parsed_body["data"]
        expect(data.length).to eq(1)
        expect(data.first["name"]).to eq("Gamma Fitness Center")
      end
    end
  end

  # ==================================================
  # SUPER ADMIN — sees only their own venues
  # ==================================================

  context "when authenticated as super_admin" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only venues they own" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).to include("Beta Sports Complex")
      expect(names).not_to include("Alpha Sports Arena")
    end
  end

  # ==================================================
  # STAFF WITH READ PERMISSION FOR VENUES
  # ==================================================

  context "when authenticated as staff with venues:read permission" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    before do
      permission = create(:permission, resource: "venues", action: "read")
      role = create(:role, venue: venue1)
      create(:role_permission, role: role, permission: permission)
      create(:venue_membership, user: staff_user, venue: venue1, role: role)

      params_string = query_params.present? ? "?#{query_params.to_query}" : ""
      get "#{endpoint}#{params_string}", headers: request_headers
    end

    it "returns success response" do
      expect(response).to have_http_status(:ok)
    end

    it "matches the index response schema" do
      expect(response).to match_json_schema("venues/index_response")
    end

    it "returns only the venue they are staff of" do
      data = response.parsed_body["data"]
      expect(data.length).to eq(1)
      expect(data.first["name"]).to eq("Alpha Sports Arena")
    end

    it "does not return venues they are not staff of" do
      names = response.parsed_body["data"].map { |v| v["name"] }
      expect(names).not_to include("Beta Sports Complex")
    end
  end

  # ==================================================
  # STAFF WITHOUT READ PERMISSION FOR VENUES
  # ==================================================

  context "when authenticated as staff without venues:read permission" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(staff_user)) }

    before do
      permission = create(:permission, :read_bookings)
      role = create(:role, venue: venue1)
      create(:role_permission, role: role, permission: permission)
      create(:venue_membership, user: staff_user, venue: venue1, role: role)

      params_string = query_params.present? ? "?#{query_params.to_query}" : ""
      get "#{endpoint}#{params_string}", headers: request_headers
    end

    it "returns forbidden" do
      expect(response).to have_http_status(:forbidden)
    end
  end

  # ==================================================
  # USER WITH NO ASSOCIATED VENUES
  # ==================================================

  context "when authenticated as user with no associated venues" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(unaffiliated_user)) }

    it "returns not found" do
      expect(response).to have_http_status(:not_found)
    end
  end
end
