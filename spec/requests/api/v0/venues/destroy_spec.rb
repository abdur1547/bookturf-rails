# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "DELETE /api/v0/venues/:id", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  # Create test users with roles
  let(:owner_role) { create(:role, :owner) }
  let(:admin_role) { create(:role, :admin) }
  let(:customer_role) { create(:role, :customer) }

  let(:owner_user) { create(:user, email: "owner@example.com") }
  let(:admin_user) { create(:user, email: "admin@example.com") }
  let(:another_owner) { create(:user, email: "anotherowner@example.com") }
  let(:customer_user) { create(:user, email: "customer@example.com") }

  before do
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    another_owner.assign_role(owner_role)
    customer_user.assign_role(customer_role)
  end

  # Create test venue owned by owner_user
  let!(:test_venue) do
    create(:venue,
           name: "Venue To Delete",
           city: "Karachi",
           owner: owner_user)
  end

  let(:venue_id) { test_venue.id }
  let(:endpoint) { "/api/v0/venues/#{venue_id}" }
  let(:request_headers) { headers }

  before do
    delete endpoint, headers: request_headers
  end

  # ==================================================
  # SUCCESS PATHS
  # ==================================================

  context "when authenticated as venue owner" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    context "with no dependencies" do
      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "matches the delete response schema" do
        expect(response).to match_json_schema("venues/delete_response")
      end

      it "deletes the venue from database" do
        expect(Venue.exists?(test_venue.id)).to be false
      end

      it "returns success message" do
        data = response.parsed_body["data"]
        expect(data["message"]).to eq("Venue deleted successfully")
      end

      it "returns success: true" do
        expect(response.parsed_body["success"]).to be true
      end
    end

    context "when accessing by slug instead of ID" do
      let(:venue_id) { test_venue.slug }

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "deletes the venue" do
        expect(Venue.exists?(test_venue.id)).to be false
      end

      it "returns success message" do
        data = response.parsed_body["data"]
        expect(data["message"]).to eq("Venue deleted successfully")
      end
    end

    context "when venue has settings and operating hours" do
      it "deletes the venue and cascades to related records" do
        expect(response).to have_http_status(:ok)
        expect(Venue.exists?(test_venue.id)).to be false
        expect(VenueOperatingHour.where(venue_id: test_venue.id).exists?).to be false
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

    it "does not delete the venue" do
      expect(Venue.exists?(test_venue.id)).to be true
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when authenticated as admin (non-owner)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

    it "returns forbidden status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not delete the venue" do
      expect(Venue.exists?(test_venue.id)).to be true
    end

    it "includes authorization error" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when authenticated as different owner (not the venue owner)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(another_owner)) }

    it "returns forbidden status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not delete the venue" do
      expect(Venue.exists?(test_venue.id)).to be true
    end

    it "returns authorization error" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when authenticated as customer" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

    it "returns forbidden status" do
      expect(response).to have_http_status(:forbidden)
    end

    it "does not delete the venue" do
      expect(Venue.exists?(test_venue.id)).to be true
    end

    it "returns authorization error" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when venue does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { 999999 }

    it "returns not found status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
      expect(response.parsed_body["errors"]).to be_an(Array)
    end
  end

  context "when slug does not exist" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { "non-existent-venue" }

    it "returns not found status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
      expect(response.parsed_body["errors"]).to be_an(Array)
    end
  end

  context "when venue has courts" do
    let(:courts_owner) { create(:user, email: "courtsowner@example.com") }
    let!(:court_venue) do
      courts_owner.assign_role(owner_role)
      create(:venue, owner: courts_owner)
    end
    let!(:court) { create(:court, venue: court_venue) }

    before do
      delete "/api/v0/venues/#{court_venue.id}",
             headers: headers.merge("Authorization" => auth_token_for(courts_owner))
    end

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not delete the venue" do
      expect(Venue.exists?(court_venue.id)).to be true
    end

    it "includes error about existing courts" do
      errors = response.parsed_body["errors"]
      expect(errors.to_s).to include("existing courts")
    end
  end

  context "when venue has bookings" do
    let(:bookings_owner) { create(:user, email: "bookingsowner@example.com") }
    let!(:bookings_venue) do
      bookings_owner.assign_role(owner_role)
      create(:venue, owner: bookings_owner)
    end
    # Booking's within_operating_hours validation requires operating hours for the booking day
    let!(:bookings_operating_hour) do
      create(:venue_operating_hour,
             venue: bookings_venue,
             day_of_week: 1.day.from_now.wday,
             opens_at: "09:00",
             closes_at: "23:00",
             is_closed: false)
    end
    # The booking factory creates its own court (belonging to a different venue),
    # so bookings_venue.courts.exists? stays false — ensuring the bookings check runs
    let!(:booking) { create(:booking, venue: bookings_venue, user: customer_user) }

    before do
      delete "/api/v0/venues/#{bookings_venue.id}",
             headers: headers.merge("Authorization" => auth_token_for(bookings_owner))
    end

    it "returns unprocessable entity status" do
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "does not delete the venue" do
      expect(Venue.exists?(bookings_venue.id)).to be true
    end

    it "includes error about existing bookings" do
      errors = response.parsed_body["errors"]
      expect(errors.to_s).to include("existing bookings")
    end
  end

  # ==================================================
  # EDGE CASES
  # ==================================================

  context "when venue ID is zero" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { 0 }

    it "returns not found status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when venue ID is negative" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { -1 }

    it "returns not found status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when venue ID is invalid format" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
    let(:venue_id) { "invalid@id" }

    it "returns not found status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns error response" do
      expect(response.parsed_body["success"]).to be false
    end
  end

  context "when venue is inactive" do
    let(:inactive_owner) { create(:user, email: "inactive_owner@example.com") }
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(inactive_owner)) }
    let!(:inactive_venue) do
      inactive_owner.assign_role(owner_role)
      create(:venue, is_active: false, owner: inactive_owner)
    end
    let(:venue_id) { inactive_venue.id }

    it "returns success status (can delete inactive venues)" do
      expect(response).to have_http_status(:ok)
    end

    it "deletes the inactive venue" do
      expect(Venue.exists?(inactive_venue.id)).to be false
    end
  end

  context "when deleting twice (already deleted)" do
    let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    before do
      # First deletion already happened in the outer before block
      # Try to delete again
      delete endpoint, headers: request_headers
    end

    it "returns not found status" do
      expect(response).to have_http_status(:not_found)
    end

    it "returns not found error" do
      expect(response.parsed_body["success"]).to be false
      expect(response.parsed_body["errors"]).to be_an(Array)
    end
  end

  context "when venue has venue_users (staff)" do
    # Create a separate user and venue with staff for this test
    let(:staff_owner) { create(:user, email: "staffvenueowner@example.com") }

    let(:staff_venue) do
      staff_owner.assign_role(owner_role)
      create(:venue, name: "Venue With Staff", owner: staff_owner)
    end

    let!(:venue_user) do
      create(:venue_user, venue: staff_venue, user: customer_user)
    end

    it "deletes the venue and cascades to venue_users" do
      venue_user_id = venue_user.id
      venue_id = staff_venue.id

      # Execute the delete request for this specific venue
      delete "/api/v0/venues/#{venue_id}", headers: headers.merge("Authorization" => auth_token_for(staff_owner))

      expect(response).to have_http_status(:ok)
      expect(Venue.exists?(venue_id)).to be false
      expect(VenueUser.exists?(venue_user_id)).to be false
    end
  end
end
