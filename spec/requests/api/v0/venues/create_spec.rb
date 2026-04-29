# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v0/venues", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  # Create test users with roles
  let(:owner_role) { create(:role, :owner) }
  let(:admin_role) { create(:role, :admin) }
  let(:customer_role) { create(:role, :customer) }

  let(:owner_user) { create(:user, email: "owner@example.com") }
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:customer_user) { create(:user, email: "customer@example.com") }
  let(:new_user) { create(:user, email: "newuser@example.com") }

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    customer_user.assign_role(customer_role)
    new_user.assign_role(customer_role)
  end

  let(:endpoint) { "/api/v0/venues" }
  let(:request_headers) { headers }

  # Define each parameter as a separate let variable (sent flat — no `venue:` wrapper)
  let(:venue_name) { "New Sports Arena" }
  let(:venue_description) { "A premium sports facility" }
  let(:venue_address) { "123 Main Street, Block A" }
  let(:venue_city) { "Karachi" }
  let(:venue_state) { "Sindh" }
  let(:venue_country) { "Pakistan" }
  let(:venue_postal_code) { "75600" }
  let(:venue_latitude) { 24.8607 }
  let(:venue_longitude) { 67.0011 }
  let(:venue_phone_number) { "+92 21 35123456" }
  let(:venue_email) { "info@newsportsarena.com" }
  let(:venue_is_active) { true }
  let(:venue_timezone) { "Asia/Karachi" }
  let(:venue_currency) { "PKR" }

  # Operating hours for all 7 days
  let(:venue_operating_hours_params) do
    [
      { day_of_week: 0, opens_at: "09:00", closes_at: "23:00", is_closed: false },
      { day_of_week: 1, opens_at: "09:00", closes_at: "23:00", is_closed: false },
      { day_of_week: 2, opens_at: "09:00", closes_at: "23:00", is_closed: false },
      { day_of_week: 3, opens_at: "09:00", closes_at: "23:00", is_closed: false },
      { day_of_week: 4, opens_at: "09:00", closes_at: "23:00", is_closed: false },
      { day_of_week: 5, opens_at: "09:00", closes_at: "23:00", is_closed: false },
      { day_of_week: 6, opens_at: "08:00", closes_at: "00:00", is_closed: false }
    ]
  end

  let(:request_params) do
    {
      name: venue_name,
      description: venue_description,
      address: venue_address,
      city: venue_city,
      state: venue_state,
      country: venue_country,
      postal_code: venue_postal_code,
      latitude: venue_latitude,
      longitude: venue_longitude,
      phone_number: venue_phone_number,
      email: venue_email,
      is_active: venue_is_active,
      timezone: venue_timezone,
      currency: venue_currency,
      venue_operating_hours: venue_operating_hours_params
    }
  end

  before do
    post endpoint, params: request_params.to_json, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as new user (can create venue)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }

    context "with complete valid parameters" do
      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "matches the create response schema" do
        expect(response).to match_json_schema("venues/create_response")
      end

      it "creates a new venue" do
        expect(Venue.where(name: venue_name)).to exist
      end

      it "sets the current user as the owner" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.owner_id).to eq(new_user.id)
      end

      it "generates a slug from the name" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.slug).to eq("new-sports-arena")
      end

      it "returns the created venue with complete attributes" do
        data = response.parsed_body["data"]
        expect(data).to include(
          "name" => "New Sports Arena",
          "description" => "A premium sports facility",
          "address" => "123 Main Street, Block A",
          "city" => "Karachi",
          "state" => "Sindh",
          "country" => "Pakistan",
          "postal_code" => "75600",
          "phone_number" => "+92 21 35123456",
          "email" => "info@newsportsarena.com",
          "is_active" => true
        )
      end

      it "stores the timezone and currency" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.timezone).to eq("Asia/Karachi")
        expect(new_venue.currency).to eq("PKR")
      end

      it "includes timezone and currency in response" do
        data = response.parsed_body["data"]
        expect(data["timezone"]).to eq("Asia/Karachi")
        expect(data["currency"]).to eq("PKR")
      end

      it "creates all 7 operating hours" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.venue_operating_hours.count).to eq(7)
      end

      it "includes venue_operating_hours in response" do
        data = response.parsed_body["data"]
        expect(data["venue_operating_hours"]).to be_an(Array)
        expect(data["venue_operating_hours"].length).to eq(7)
      end

      it "includes owner information in response" do
        data = response.parsed_body["data"]
        expect(data["owner"]["id"]).to eq(new_user.id)
        expect(data["owner"]["full_name"]).to eq(new_user.full_name)
      end
    end

    context "with minimal parameters (only required fields)" do
      let(:venue_description) { nil }
      let(:venue_postal_code) { nil }
      let(:venue_latitude) { nil }
      let(:venue_longitude) { nil }
      let(:venue_phone_number) { nil }
      let(:venue_email) { nil }
      let(:venue_timezone) { nil }
      let(:venue_currency) { nil }
      let(:venue_operating_hours_params) { nil }

      it "creates the venue successfully" do
        expect(response).to have_http_status(:created)
      end

      it "creates venue with default timezone and currency" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.timezone).to eq("Asia/Karachi")
        expect(new_venue.currency).to eq("PKR")
      end

      it "creates default operating hours (7 days)" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.venue_operating_hours.count).to eq(7)
      end
    end

    context "with custom timezone and currency" do
      let(:venue_timezone) { "Asia/Dubai" }
      let(:venue_currency) { "AED" }

      it "creates the venue successfully" do
        expect(response).to have_http_status(:created)
      end

      it "stores the custom timezone and currency" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.timezone).to eq("Asia/Dubai")
        expect(new_venue.currency).to eq("AED")
      end
    end

    context "with some closed days in operating hours" do
      let(:venue_operating_hours_params) do
        [
          { day_of_week: 0, opens_at: "09:00", closes_at: "23:00", is_closed: true },
          { day_of_week: 1, opens_at: "09:00", closes_at: "23:00", is_closed: false },
          { day_of_week: 2, opens_at: "09:00", closes_at: "23:00", is_closed: false },
          { day_of_week: 3, opens_at: "09:00", closes_at: "23:00", is_closed: false },
          { day_of_week: 4, opens_at: "09:00", closes_at: "23:00", is_closed: false },
          { day_of_week: 5, opens_at: "09:00", closes_at: "23:00", is_closed: false },
          { day_of_week: 6, opens_at: "09:00", closes_at: "23:00", is_closed: true }
        ]
      end

      it "creates the venue successfully" do
        expect(response).to have_http_status(:created)
      end

      it "marks specified days as closed" do
        new_venue = Venue.find_by(name: venue_name)
        sunday = new_venue.venue_operating_hours.find_by(day_of_week: 0)
        saturday = new_venue.venue_operating_hours.find_by(day_of_week: 6)
        expect(sunday.is_closed).to be true
        expect(saturday.is_closed).to be true
      end
    end

    context "with name containing special characters" do
      let(:venue_name) { "ABC Sports & Recreation Center" }

      it "creates the venue successfully" do
        expect(response).to have_http_status(:created)
      end

      it "generates valid slug" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.slug).to eq("abc-sports-recreation-center")
      end
    end

    context "when is_active is false" do
      let(:venue_is_active) { false }

      it "creates the venue as inactive" do
        expect(response).to have_http_status(:created)
      end

      it "sets is_active to false" do
        new_venue = Venue.find_by(name: venue_name)
        expect(new_venue.is_active).to be false
      end
    end
  end

  # ==================================================
  # FAILURE PATHS
  # ==================================================

  context "when not authenticated" do
    let(:request_headers) { headers }

    it "returns unauthorized status" do
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
    end

    it "does not create a venue" do
      expect(Venue.where(name: venue_name)).not_to exist
    end
  end

  context "when authenticated as owner who already has a venue" do
    let!(:owner_with_venue) do
      user = create(:user, email: "owner_with_venue@example.com")
      user.assign_role(owner_role)
      # Create the existing venue here so it's present before the request runs
      venue = Venue.new(
        owner_id: user.id,
        name: "Existing Venue",
        address: "123 Existing St",
        timezone: "Asia/Karachi",
        currency: "PKR",
        slug: "existing-venue-test-#{SecureRandom.hex(4)}"
      )
      venue.save!(validate: false)
      user
    end

    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_with_venue)) }

    it "returns validation error" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes error about existing venue" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
      expect(errors.to_s).to include("can only own one venue")
    end

    it "does not create a new venue" do
      expect(owner_with_venue.reload.owned_venues.count).to eq(1)
      expect(owner_with_venue.owned_venues.first.name).to eq("Existing Venue")
    end
  end

  context "when name is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_name) { nil }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns validation error" do
      expect(response.parsed_body["success"]).to be false
    end

    it "does not create a venue" do
      expect(Venue.count).to eq(0)
    end
  end

  context "when name is empty string" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_name) { "" }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes name validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when name is too short" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_name) { "AB" }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when address is missing" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_address) { nil }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes address validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when email format is invalid" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_email) { "invalid-email-format" }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes email validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when phone_number format is invalid" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_phone_number) { "invalid phone!" }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes phone validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when latitude is out of range" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_latitude) { 95.0 }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes latitude validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when longitude is out of range" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_longitude) { -185.0 }

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes longitude validation error" do
      errors = response.parsed_body["errors"]
      expect(errors).to be_present
    end
  end

  context "when operating hours are incomplete (missing days)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_operating_hours_params) do
      [
        { day_of_week: 0, opens_at: "09:00", closes_at: "23:00", is_closed: false },
        { day_of_week: 1, opens_at: "09:00", closes_at: "23:00", is_closed: false }
        # Missing days 2-6
      ]
    end

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes validation error about missing days" do
      errors = response.parsed_body["errors"]
      expect(errors.to_s).to include("All 7 days must be provided")
    end
  end

  context "when operating hours have closes_at equal to opens_at" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_operating_hours_params) do
      [
        { day_of_week: 0, opens_at: "09:00", closes_at: "09:00", is_closed: false },
        { day_of_week: 1, opens_at: "09:00", closes_at: "23:00", is_closed: false },
        { day_of_week: 2, opens_at: "09:00", closes_at: "23:00", is_closed: false },
        { day_of_week: 3, opens_at: "09:00", closes_at: "23:00", is_closed: false },
        { day_of_week: 4, opens_at: "09:00", closes_at: "23:00", is_closed: false },
        { day_of_week: 5, opens_at: "09:00", closes_at: "23:00", is_closed: false },
        { day_of_week: 6, opens_at: "09:00", closes_at: "23:00", is_closed: false }
      ]
    end

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "includes validation error about time order" do
      errors = response.parsed_body["errors"]
      expect(errors.to_s).to include("must be different")
    end
  end

  # ==================================================
  # EDGE CASES
  # ==================================================

  context "when name has leading/trailing whitespace" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_name) { "  Whitespace Arena  " }

    it "creates the venue successfully" do
      expect(response).to have_http_status(:created)
    end
  end

  context "when coordinates are at boundary values" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }
    let(:venue_latitude) { 90.0 }
    let(:venue_longitude) { 180.0 }

    it "creates the venue successfully" do
      expect(response).to have_http_status(:created)
    end

    it "stores the boundary coordinates" do
      new_venue = Venue.find_by(name: venue_name)
      expect(new_venue.latitude).to eq(90.0)
      expect(new_venue.longitude).to eq(180.0)
    end
  end

  context "when request body structure is invalid" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(new_user)) }

    before do
      post endpoint, params: { invalid: "structure" }.to_json, headers: request_headers
    end

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns validation error" do
      expect(response.parsed_body["success"]).to be false
    end
  end
end
