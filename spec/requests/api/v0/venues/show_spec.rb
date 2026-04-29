# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "GET /api/v0/venues/:id", type: :request do
#   let(:headers) { { "Content-Type" => "application/json" } }

#   # Create test users with roles
#   let(:owner_role) { create(:role, :owner) }
#   let(:admin_role) { create(:role, :admin) }
#   let(:customer_role) { create(:role, :customer) }

#   let(:owner_user) { create(:user, email: "owner@example.com") }
#   let(:admin_user) { create(:user, email: "admin@example.com") }
#   let(:customer_user) { create(:user, email: "customer@example.com") }

#   before do
#     owner_user.assign_role(owner_role)
#     admin_user.assign_role(admin_role)
#     customer_user.assign_role(customer_role)
#   end

#   # Create test venue
#   let!(:test_venue) do
#     create(:venue,
#            name: "Premium Sports Arena",
#            slug: "premium-sports-arena",
#            description: "State of the art sports facility",
#            city: "Karachi",
#            state: "Sindh",
#            country: "Pakistan",
#            latitude: 24.8607,
#            longitude: 67.0011,
#            is_active: true,
#            owner: owner_user)
#   end

#   let(:venue_id) { test_venue.id }
#   let(:endpoint) { "/api/v0/venues/#{venue_id}" }
#   let(:request_headers) { headers }

#   before do
#     get endpoint, headers: request_headers
#   end

#   # ==================================================
#   # SUCCESS PATHS
#   # ==================================================

#   context "when not authenticated (public access)" do
#     let(:request_headers) { headers }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "matches the show response schema" do
#       expect(response).to match_json_schema("venues/show_response")
#     end

#     it "returns the correct venue" do
#       data = response.parsed_body["data"]
#       expect(data["id"]).to eq(test_venue.id)
#       expect(data["name"]).to eq("Premium Sports Arena")
#       expect(data["slug"]).to eq("premium-sports-arena")
#     end

#     it "includes complete venue attributes" do
#       data = response.parsed_body["data"]
#       expect(data).to include(
#         "id" => test_venue.id,
#         "name" => "Premium Sports Arena",
#         "slug" => "premium-sports-arena",
#         "description" => "State of the art sports facility",
#         "address" => be_a(String),
#         "city" => "Karachi",
#         "state" => "Sindh",
#         "country" => "Pakistan",
#         "latitude" => be_a(Float),
#         "longitude" => be_a(Float),
#         "is_active" => true,
#         "created_at" => be_a(String),
#         "updated_at" => be_a(String)
#       )
#     end

#     it "includes google_maps_url" do
#       data = response.parsed_body["data"]
#       expect(data["google_maps_url"]).to be_present
#       expect(data["google_maps_url"]).to include("google.com/maps")
#       expect(data["google_maps_url"]).to include("24.8607")
#       expect(data["google_maps_url"]).to include("67.0011")
#     end

#     it "includes owner information" do
#       data = response.parsed_body["data"]
#       expect(data["owner"]).to be_present
#       expect(data["owner"]).to include(
#         "id" => owner_user.id,
#         "email" => "owner@example.com",
#         "name" => be_a(String)
#       )
#     end

#     it "includes venue_setting information" do
#       data = response.parsed_body["data"]
#       expect(data["venue_setting"]).to be_present
#       expect(data["venue_setting"]).to include(
#         "id" => be_a(Integer),
#         "minimum_slot_duration" => be_a(Integer),
#         "maximum_slot_duration" => be_a(Integer),
#         "slot_interval" => be_a(Integer),
#         "advance_booking_days" => be_a(Integer),
#         "requires_approval" => be_in([ true, false ]),
#         "timezone" => be_a(String),
#         "currency" => be_a(String)
#       )
#     end

#     it "includes venue_operating_hours array" do
#       data = response.parsed_body["data"]
#       expect(data["venue_operating_hours"]).to be_an(Array)
#       expect(data["venue_operating_hours"].length).to eq(7)
#     end

#     it "includes complete operating hours for each day" do
#       data = response.parsed_body["data"]
#       operating_hour = data["venue_operating_hours"].first
#       expect(operating_hour).to include(
#         "id" => be_a(Integer),
#         "day_of_week" => be_between(0, 6),
#         "is_closed" => be_in([ true, false ]),
#         "day_name" => be_a(String),
#         "formatted_hours" => be_a(String)
#       )
#     end

#     it "includes courts_count" do
#       data = response.parsed_body["data"]
#       expect(data["courts_count"]).to eq(0)
#     end

#     context "when accessing by slug instead of ID" do
#       let(:venue_id) { "premium-sports-arena" }

#       it "returns success response" do
#         expect(response).to have_http_status(:ok)
#       end

#       it "returns the correct venue" do
#         data = response.parsed_body["data"]
#         expect(data["id"]).to eq(test_venue.id)
#         expect(data["slug"]).to eq("premium-sports-arena")
#       end

#       it "matches the show response schema" do
#         expect(response).to match_json_schema("venues/show_response")
#       end
#     end

#     context "when venue has no coordinates" do
#       let!(:venue_no_coords) do
#         create(:venue, :without_coordinates, owner: admin_user)
#       end
#       let(:venue_id) { venue_no_coords.id }

#       it "returns success response" do
#         expect(response).to have_http_status(:ok)
#       end

#       it "returns null google_maps_url" do
#         data = response.parsed_body["data"]
#         expect(data["google_maps_url"]).to be_nil
#       end

#       it "includes latitude and longitude as null" do
#         data = response.parsed_body["data"]
#         expect(data["latitude"]).to be_nil
#         expect(data["longitude"]).to be_nil
#       end
#     end

#     context "when venue is inactive" do
#       let!(:inactive_venue) do
#         create(:venue, is_active: false, owner: admin_user)
#       end
#       let(:venue_id) { inactive_venue.id }

#       it "returns success response (public can view)" do
#         expect(response).to have_http_status(:ok)
#       end

#       it "shows is_active as false" do
#         data = response.parsed_body["data"]
#         expect(data["is_active"]).to be false
#       end
#     end
#   end

#   context "when authenticated as owner" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "matches the show response schema" do
#       expect(response).to match_json_schema("venues/show_response")
#     end

#     it "returns complete venue details" do
#       data = response.parsed_body["data"]
#       expect(data["id"]).to eq(test_venue.id)
#       expect(data["owner"]["id"]).to eq(owner_user.id)
#     end
#   end

#   context "when authenticated as admin" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "returns venue details" do
#       data = response.parsed_body["data"]
#       expect(data["id"]).to eq(test_venue.id)
#     end
#   end

#   context "when authenticated as customer" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "returns venue details (public endpoint)" do
#       data = response.parsed_body["data"]
#       expect(data["id"]).to eq(test_venue.id)
#     end
#   end

#   # ==================================================
#   # FAILURE PATHS
#   # ==================================================

#   context "when venue does not exist" do
#     let(:venue_id) { 999999 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#       expect(response.parsed_body["errors"]).to be_present
#     end

#     it "includes not found error message" do
#       expect(response.parsed_body["errors"]).to eq({ "error" => "Venue not found" })
#     end
#   end

#   context "when slug does not exist" do
#     let(:venue_id) { "non-existent-venue-slug" }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#       expect(response.parsed_body["errors"]).to eq({ "error" => "Venue not found" })
#     end
#   end

#   context "when ID is invalid format" do
#     let(:venue_id) { "invalid@id" }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#     end
#   end

#   # ==================================================
#   # EDGE CASES
#   # ==================================================

#   context "when venue ID is zero" do
#     let(:venue_id) { 0 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#     end
#   end

#   context "when venue ID is negative" do
#     let(:venue_id) { -1 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#     end
#   end

#   context "when venue has all 7 operating hours" do
#     it "returns all days in order" do
#       data = response.parsed_body["data"]
#       days = data["venue_operating_hours"].map { |h| h["day_of_week"] }
#       expect(days).to eq([ 0, 1, 2, 3, 4, 5, 6 ])
#     end

#     it "includes day names for each operating hour" do
#       data = response.parsed_body["data"]
#       day_names = data["venue_operating_hours"].map { |h| h["day_name"] }
#       expect(day_names).to include("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday")
#     end
#   end
# end
