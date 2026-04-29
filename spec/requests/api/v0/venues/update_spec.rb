# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "PATCH /api/v0/venues/:id", type: :request do
#   let(:headers) { { "Content-Type" => "application/json" } }

#   # Create test users with roles
#   let(:owner_role) { create(:role, :owner) }
#   let(:admin_role) { create(:role, :admin) }
#   let(:customer_role) { create(:role, :customer) }

#   let(:owner_user) { create(:user, email: "owner@example.com") }
#   let(:admin_user) { create(:user, email: "admin@example.com") }
#   let(:another_owner) { create(:user, email: "anotherowner@example.com") }
#   let(:customer_user) { create(:user, email: "customer@example.com") }

#   before do
#     owner_user.assign_role(owner_role)
#     admin_user.assign_role(admin_role)
#     another_owner.assign_role(owner_role)
#     customer_user.assign_role(customer_role)
#   end

#   # Create test venue owned by owner_user
#   let!(:test_venue) do
#     create(:venue,
#            name: "Original Arena",
#            description: "Original description",
#            city: "Karachi",
#            state: "Sindh",
#            is_active: true,
#            owner: owner_user)
#   end

#   let(:venue_id) { test_venue.id }
#   let(:endpoint) { "/api/v0/venues/#{venue_id}" }
#   let(:request_headers) { headers }

#   # Define update parameters
#   let(:updated_name) { "Updated Sports Arena" }
#   let(:updated_description) { "Updated description" }
#   let(:updated_city) { "Lahore" }
#   let(:updated_state) { "Punjab" }
#   let(:updated_phone) { "+92 42 12345678" }
#   let(:updated_email) { "updated@venue.com" }
#   let(:updated_is_active) { false }

#   let(:updated_setting_params) do
#     {
#       minimum_slot_duration: 90,
#       timezone: "Asia/Dubai"
#     }
#   end

#   let(:updated_operating_hours_params) do
#     [
#       { day_of_week: 0, is_closed: true },
#       { day_of_week: 1, opens_at: "08:00", closes_at: "22:00", is_closed: false },
#       { day_of_week: 2, opens_at: "08:00", closes_at: "22:00", is_closed: false },
#       { day_of_week: 3, opens_at: "08:00", closes_at: "22:00", is_closed: false },
#       { day_of_week: 4, opens_at: "08:00", closes_at: "22:00", is_closed: false },
#       { day_of_week: 5, opens_at: "08:00", closes_at: "22:00", is_closed: false },
#       { day_of_week: 6, is_closed: true }
#     ]
#   end

#   let(:request_params) do
#     venue_hash = {
#       name: updated_name,
#       description: updated_description,
#       city: updated_city,
#       state: updated_state,
#       phone_number: updated_phone,
#       email: updated_email,
#       is_active: updated_is_active
#     }.compact

#     venue_hash[:venue_setting] = updated_setting_params if updated_setting_params
#     venue_hash[:venue_operating_hours] = updated_operating_hours_params if updated_operating_hours_params

#     { venue: venue_hash }
#   end

#   before do
#     patch endpoint, params: request_params.to_json, headers: request_headers
#   end

#   # ==================================================
#   # SUCCESS PATHS
#   # ==================================================

#   context "when authenticated as venue owner" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#     context "with complete valid parameters" do
#       it "returns success status" do
#         expect(response).to have_http_status(:ok)
#       end

#       it "matches the show response schema" do
#         expect(response).to match_json_schema("venues/show_response")
#       end

#       it "updates the venue name" do
#         test_venue.reload
#         expect(test_venue.name).to eq("Updated Sports Arena")
#       end

#       it "updates the venue description" do
#         test_venue.reload
#         expect(test_venue.description).to eq("Updated description")
#       end

#       it "updates the city and state" do
#         test_venue.reload
#         expect(test_venue.city).to eq("Lahore")
#         expect(test_venue.state).to eq("Punjab")
#       end

#       it "returns the updated venue in response" do
#         data = response.parsed_body["data"]
#         expect(data).to include(
#           "name" => "Updated Sports Arena",
#           "description" => "Updated description",
#           "city" => "Lahore",
#           "state" => "Punjab"
#         )
#       end

#       it "updates venue settings" do
#         test_venue.reload
#         expect(test_venue.venue_setting.minimum_slot_duration).to eq(90)
#         expect(test_venue.venue_setting.timezone).to eq("Asia/Dubai")
#       end

#       it "updates operating hours" do
#         test_venue.reload
#         sunday = test_venue.venue_operating_hours.find_by(day_of_week: 0)
#         monday = test_venue.venue_operating_hours.find_by(day_of_week: 1)

#         expect(sunday.is_closed).to be true
#         expect(monday.opens_at.strftime("%H:%M")).to eq("08:00")
#       end

#       it "includes updated settings in response" do
#         data = response.parsed_body["data"]
#         expect(data["venue_setting"]["minimum_slot_duration"]).to eq(90)
#         expect(data["venue_setting"]["timezone"]).to eq("Asia/Dubai")
#       end

#       it "includes updated operating hours in response" do
#         data = response.parsed_body["data"]
#         sunday_hours = data["venue_operating_hours"].find { |h| h["day_of_week"] == 0 }
#         expect(sunday_hours["is_closed"]).to be true
#       end
#     end

#     context "with partial update (only name)" do
#       let(:updated_description) { nil }
#       let(:updated_city) { nil }
#       let(:updated_state) { nil }
#       let(:updated_phone) { nil }
#       let(:updated_email) { nil }
#       let(:updated_is_active) { nil }
#       let(:updated_setting_params) { nil }
#       let(:updated_operating_hours_params) { nil }

#       let(:request_params) do
#         {
#           venue: {
#             name: updated_name
#           }
#         }
#       end

#       it "updates only the specified field" do
#         test_venue.reload
#         expect(test_venue.name).to eq("Updated Sports Arena")
#       end

#       it "keeps other fields unchanged" do
#         test_venue.reload
#         expect(test_venue.city).to eq("Karachi")
#         expect(test_venue.state).to eq("Sindh")
#         expect(test_venue.description).to eq("Original description")
#       end

#       it "returns success status" do
#         expect(response).to have_http_status(:ok)
#       end
#     end

#     context "with partial setting update" do
#       let(:updated_name) { nil }
#       let(:updated_description) { nil }
#       let(:updated_city) { nil }
#       let(:updated_state) { nil }
#       let(:updated_phone) { nil }
#       let(:updated_email) { nil }
#       let(:updated_is_active) { nil }
#       let(:updated_operating_hours_params) { nil }

#       let(:request_params) do
#         {
#           venue: {
#             venue_setting: { timezone: "Asia/Tokyo" }
#           }
#         }
#       end

#       it "updates only the specified setting" do
#         test_venue.reload
#         expect(test_venue.venue_setting.timezone).to eq("Asia/Tokyo")
#       end

#       it "keeps other settings unchanged" do
#         test_venue.reload
#         expect(test_venue.venue_setting.minimum_slot_duration).to eq(60)
#       end

#       it "returns success status" do
#         expect(response).to have_http_status(:ok)
#       end
#     end

#     context "with partial operating hours update" do
#       let(:updated_name) { nil }
#       let(:updated_description) { nil }
#       let(:updated_city) { nil }
#       let(:updated_state) { nil }
#       let(:updated_phone) { nil }
#       let(:updated_email) { nil }
#       let(:updated_is_active) { nil }
#       let(:updated_setting_params) { nil }

#       let(:updated_operating_hours_params) do
#         [
#           { day_of_week: 0, opens_at: "10:00", closes_at: "20:00", is_closed: false },
#           { day_of_week: 1, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#           { day_of_week: 2, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#           { day_of_week: 3, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#           { day_of_week: 4, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#           { day_of_week: 5, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#           { day_of_week: 6, opens_at: "09:00", closes_at: "23:00", is_closed: false }
#         ]
#       end

#       it "updates the operating hours" do
#         test_venue.reload
#         sunday = test_venue.venue_operating_hours.find_by(day_of_week: 0)
#         expect(sunday.opens_at.strftime("%H:%M")).to eq("10:00")
#         expect(sunday.closes_at.strftime("%H:%M")).to eq("20:00")
#       end

#       it "returns success status" do
#         expect(response).to have_http_status(:ok)
#       end
#     end

#     context "when updating slug (should be ignored)" do
#       let(:original_slug) { test_venue.slug }

#       let(:request_params) do
#         {
#           venue: {
#             slug: "should-not-change",
#             name: "New Name"
#           }
#         }
#       end

#       it "does not update the slug" do
#         test_venue.reload
#         expect(test_venue.slug).to eq(original_slug)
#         expect(test_venue.slug).not_to eq("should-not-change")
#       end

#       it "updates allowed fields" do
#         test_venue.reload
#         expect(test_venue.name).to eq("New Name")
#       end
#     end

#     context "when updating owner_id (should be ignored)" do
#       let(:request_params) do
#         {
#           venue: {
#             owner_id: another_owner.id,
#             name: "New Name"
#           }
#         }
#       end

#       it "does not change the owner" do
#         test_venue.reload
#         expect(test_venue.owner_id).to eq(owner_user.id)
#         expect(test_venue.owner_id).not_to eq(another_owner.id)
#       end

#       it "updates allowed fields" do
#         test_venue.reload
#         expect(test_venue.name).to eq("New Name")
#       end
#     end

#     context "when accessing by slug instead of ID" do
#       let(:venue_id) { test_venue.slug }

#       it "returns success status" do
#         expect(response).to have_http_status(:ok)
#       end

#       it "updates the venue" do
#         test_venue.reload
#         expect(test_venue.name).to eq("Updated Sports Arena")
#       end
#     end
#   end

#   context "when authenticated as admin (non-owner)" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

#     # Admins should be able to update based on VenuePolicy
#     it "returns success status" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "updates the venue" do
#       test_venue.reload
#       expect(test_venue.name).to eq("Updated Sports Arena")
#     end
#   end

#   # ==================================================
#   # FAILURE PATHS
#   # ==================================================

#   context "when not authenticated" do
#     let(:request_headers) { headers }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the venue" do
#       test_venue.reload
#       expect(test_venue.name).to eq("Original Arena")
#     end
#   end

#   context "when authenticated as different owner (not the venue owner)" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(another_owner)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the venue" do
#       test_venue.reload
#       expect(test_venue.name).to eq("Original Arena")
#     end
#   end

#   context "when authenticated as customer" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the venue" do
#       test_venue.reload
#       expect(test_venue.name).to eq("Original Arena")
#     end
#   end

#   context "when venue does not exist" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:venue_id) { 999999 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#       expect(response.parsed_body["errors"]).to eq({ "error" => "Venue not found" })
#     end
#   end

#   context "when name is updated to empty string" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:updated_name) { "" }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "does not update the venue" do
#       test_venue.reload
#       expect(test_venue.name).to eq("Original Arena")
#     end

#     it "includes validation error" do
#       errors = response.parsed_body["errors"]
#       expect(errors).to be_present
#     end
#   end

#   context "when email format is invalid" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:updated_email) { "invalid-email" }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "does not update the venue" do
#       test_venue.reload
#       expect(test_venue.email).not_to eq("invalid-email")
#     end
#   end

#   context "when trying to deactivate venue with active bookings" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let!(:pending_booking) do
#       # This would need Booking factory - for now it's a placeholder
#       # create(:booking, venue: test_venue, status: :pending)
#     end

#     # Skip this test if Booking model is not ready yet
#     xit "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     xit "includes error about active bookings" do
#       errors = response.parsed_body["errors"]
#       expect(errors.to_s).to include("active bookings")
#     end
#   end

#   context "when operating hours have invalid time order" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:updated_operating_hours_params) do
#       [
#         { day_of_week: 0, opens_at: "09:00", closes_at: "09:00", is_closed: false },
#         { day_of_week: 1, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#         { day_of_week: 2, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#         { day_of_week: 3, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#         { day_of_week: 4, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#         { day_of_week: 5, opens_at: "09:00", closes_at: "23:00", is_closed: false },
#         { day_of_week: 6, opens_at: "09:00", closes_at: "23:00", is_closed: false }
#       ]
#     end

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "includes validation error" do
#       errors = response.parsed_body["errors"]
#       expect(errors.to_s).to include("must be different")
#     end
#   end

#   context "when setting maximum less than minimum" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:updated_setting_params) do
#       {
#         minimum_slot_duration: 180,
#         maximum_slot_duration: 60
#       }
#     end

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "does not update settings" do
#       test_venue.reload
#       expect(test_venue.venue_setting.minimum_slot_duration).not_to eq(180)
#     end
#   end

#   # ==================================================
#   # EDGE CASES
#   # ==================================================

#   context "with empty request body" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:request_params) { { venue: {} } }

#     it "returns success status (no changes)" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "does not change the venue" do
#       test_venue.reload
#       expect(test_venue.name).to eq("Original Arena")
#     end
#   end

#   context "when updating latitude and longitude" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:request_params) do
#       {
#         venue: {
#           latitude: 25.1234,
#           longitude: 68.5678
#         }
#       }
#     end

#     it "updates the coordinates" do
#       test_venue.reload
#       expect(test_venue.latitude).to eq(25.1234)
#       expect(test_venue.longitude).to eq(68.5678)
#     end

#     it "includes updated google_maps_url in response" do
#       data = response.parsed_body["data"]
#       expect(data["google_maps_url"]).to include("25.1234")
#       expect(data["google_maps_url"]).to include("68.5678")
#     end
#   end

#   context "when setting coordinates to null" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:request_params) do
#       {
#         venue: {
#           latitude: nil,
#           longitude: nil
#         }
#       }
#     end

#     it "clears the coordinates" do
#       test_venue.reload
#       expect(test_venue.latitude).to be_nil
#       expect(test_venue.longitude).to be_nil
#     end

#     it "returns null google_maps_url" do
#       data = response.parsed_body["data"]
#       expect(data["google_maps_url"]).to be_nil
#     end
#   end
# end
