# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "GET /api/v0/roles/:id", type: :request do
#   let(:headers) { { "Content-Type" => "application/json" } }

#   # Create system roles
#   let(:owner_role) { create(:role, :owner) }
#   let(:admin_role) { create(:role, :admin) }
#   let(:receptionist_role) { create(:role, :receptionist) }
#   let(:customer_role) { create(:role, :customer) }

#   # Create test users
#   let(:owner_user) { create(:user, email: "owner@example.com") }
#   let(:admin_user) { create(:user, email: "admin@example.com") }
#   let(:receptionist_user) { create(:user, email: "receptionist@example.com") }
#   let(:customer_user) { create(:user, email: "customer@example.com") }

#   # Create permissions for testing
#   let(:create_bookings_permission) { create(:permission, :create_bookings) }
#   let(:read_bookings_permission) { create(:permission, :read_bookings) }
#   let(:manage_bookings_permission) { create(:permission, :manage_bookings) }
#   let(:read_courts_permission) { create(:permission, :read_courts) }

#   before do
#     # Assign roles to users
#     owner_user.assign_role(owner_role)
#     admin_user.assign_role(admin_role)
#     receptionist_user.assign_role(receptionist_role)
#     customer_user.assign_role(customer_role)
#   end

#   let(:role_id) { test_role.id }
#   let(:endpoint) { "/api/v0/roles/#{role_id}" }
#   let(:request_headers) { headers }
#   let(:test_role) { create(:role, :custom_role, name: "Test Role", description: "Test Description") }
#   let(:test_user) { create(:user, email: "roleuser@example.com") }

#   before do
#     test_role.add_permission(create_bookings_permission)
#     test_role.add_permission(read_bookings_permission)
#     test_user&.assign_role(test_role)

#     get endpoint, headers: request_headers
#   end

#   # SUCCESS PATHS
#   context "when authenticated as owner" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "matches the show response schema" do
#       expect(response).to match_json_schema("roles/show_response")
#     end

#     it "returns complete role details" do
#       data = response.parsed_body["data"]
#       expect(data).to match(
#         "id" => test_role.id,
#         "name" => "Test Role",
#         "slug" => test_role.slug,
#         "description" => "Test Description",
#         "is_custom" => true,
#         "created_at" => be_a(String),
#         "updated_at" => be_a(String),
#         "permissions" => be_an(Array),
#         "users" => be_an(Array)
#       )
#     end

#     it "includes associated permissions with complete structure" do
#       data = response.parsed_body["data"]
#       expect(data["permissions"]).to be_an(Array)
#       expect(data["permissions"].length).to eq(2)

#       permission_data = data["permissions"].first
#       expect(permission_data).to include(
#         "id" => be_a(Integer),
#         "name" => be_a(String),
#         "resource" => be_a(String),
#         "action" => be_a(String),
#         "description" => be_a(String)
#       )
#     end

#     it "includes associated users with complete structure" do
#       data = response.parsed_body["data"]
#       expect(data["users"]).to be_an(Array)
#       expect(data["users"].length).to eq(1)

#       user_data = data["users"].first
#       expect(user_data).to include(
#         "id" => be_a(Integer),
#         "name" => be_a(String)
#       )
#     end

#     it "returns correct permissions for the role" do
#       data = response.parsed_body["data"]
#       permission_ids = data["permissions"].map { |p| p["id"] }
#       expect(permission_ids).to match_array([
#         create_bookings_permission.id,
#         read_bookings_permission.id
#       ])
#     end

#     context "when role has no permissions" do
#       let(:test_role) { create(:role, :custom_role, name: "Empty Role") }
#       let(:test_user) { nil }

#       before do
#         # Clear any permissions added by outer before block
#         test_role.role_permissions.destroy_all
#         get endpoint, headers: request_headers
#       end

#       it "returns empty permissions array" do
#         data = response.parsed_body["data"]
#         expect(data["permissions"]).to eq([])
#       end
#     end

#     context "when role has no users" do
#       let(:test_role) { create(:role, :custom_role, name: "Unassigned Role") }
#       let(:test_user) { nil }

#       before do
#         test_role.add_permission(create_bookings_permission)
#         get endpoint, headers: request_headers
#       end

#       it "returns empty users array" do
#         data = response.parsed_body["data"]
#         expect(data["users"]).to eq([])
#       end
#     end

#     context "when fetching a system role" do
#       let(:test_role) { owner_role }

#       it "returns the system role successfully" do
#         expect(response).to have_http_status(:ok)
#         data = response.parsed_body["data"]
#         expect(data["is_custom"]).to be false
#       end
#     end
#   end

#   context "when authenticated as admin" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "returns role details" do
#       data = response.parsed_body["data"]
#       expect(data["id"]).to eq(test_role.id)
#     end
#   end

#   # FAILURE PATHS
#   context "when authenticated as receptionist (insufficient permissions)" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "matches error response schema" do
#       expect(response).to match_json_schema("error_response")
#     end

#     it "includes authorization error message" do
#       expect(response.parsed_body["errors"]).to include(
#         match(/not authorized/i)
#       )
#     end
#   end

#   context "when authenticated as customer" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end
#   end

#   context "when role does not exist" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:role_id) { 99999 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "matches error response schema" do
#       expect(response).to match_json_schema("error_response")
#     end

#     it "includes not found error message" do
#       expect(response.parsed_body["errors"]).to be_present
#     end
#   end

#   context "when not authenticated" do
#     let(:request_headers) { headers }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#     end
#   end

#   context "when role_id is invalid format" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:role_id) { "invalid-id" }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end
#   end

#   context "when role_id is zero" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:role_id) { 0 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end
#   end

#   context "when role_id is negative" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:role_id) { -1 }

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end
#   end
# end
