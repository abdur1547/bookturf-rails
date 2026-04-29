# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "PATCH /api/v0/roles/:id", type: :request do
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

#   let(:custom_role) { create(:role, :custom_role, name: "Original Name", description: "Original description") }
#   let(:role_id) { custom_role.id }
#   let(:endpoint) { "/api/v0/roles/#{role_id}" }
#   let(:request_headers) { headers }
#   let(:updated_name) { "Updated Role Name" }
#   let(:updated_description) { "Updated description" }
#   let(:updated_permission_ids) { nil }

#   let(:request_params) do
#     params = { role: {} }
#     params[:role][:name] = updated_name unless updated_name.nil?
#     params[:role][:description] = updated_description unless updated_description.nil?
#     params[:role][:permission_ids] = updated_permission_ids unless updated_permission_ids.nil?
#     params
#   end

#   before do
#     custom_role.add_permission(create_bookings_permission)
#     patch endpoint, params: request_params.to_json, headers: request_headers
#   end

#   # SUCCESS PATHS
#   context "when authenticated as owner" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#     context "updating a custom role with name and description" do
#       it "returns success response" do
#         expect(response).to have_http_status(:ok)
#       end

#       it "matches the update response schema" do
#         expect(response).to match_json_schema("roles/update_response")
#       end

#       it "updates the role name" do
#         custom_role.reload
#         expect(custom_role.name).to eq("Updated Role Name")
#       end

#       it "updates the role description" do
#         custom_role.reload
#         expect(custom_role.description).to eq("Updated description")
#       end

#       it "updates the slug based on new name" do
#         custom_role.reload
#         expect(custom_role.slug).to eq("updated_role_name")
#       end

#       it "returns the updated role in response" do
#         data = response.parsed_body["data"]
#         expect(data["name"]).to eq("Updated Role Name")
#         expect(data["description"]).to eq("Updated description")
#       end
#     end

#     context "updating only name" do
#       let(:updated_description) { nil }

#       it "updates the name successfully" do
#         custom_role.reload
#         expect(custom_role.name).to eq("Updated Role Name")
#       end

#       it "keeps the original description" do
#         custom_role.reload
#         expect(custom_role.description).to eq("Original description")
#       end
#     end

#     context "updating only description" do
#       let(:updated_name) { nil }

#       it "updates the description successfully" do
#         custom_role.reload
#         expect(custom_role.description).to eq("Updated description")
#       end

#       it "keeps the original name" do
#         custom_role.reload
#         expect(custom_role.name).to eq("Original Name")
#       end
#     end

#     context "updating permissions" do
#       let(:updated_name) { nil }
#       let(:updated_description) { nil }
#       let(:updated_permission_ids) { [ read_bookings_permission.id, manage_bookings_permission.id ] }

#       it "syncs the permissions" do
#         custom_role.reload
#         expect(custom_role.permissions.pluck(:id)).to match_array([
#           read_bookings_permission.id,
#           manage_bookings_permission.id
#         ])
#       end

#       it "removes old permissions not in the list" do
#         custom_role.reload
#         expect(custom_role.has_permission?(create_bookings_permission.name)).to be false
#       end

#       it "adds new permissions from the list" do
#         custom_role.reload
#         expect(custom_role.has_permission?(manage_bookings_permission.name)).to be true
#       end
#     end

#     context "clearing all permissions" do
#       let(:updated_name) { nil }
#       let(:updated_description) { nil }
#       let(:updated_permission_ids) { [] }

#       it "removes all permissions" do
#         custom_role.reload
#         expect(custom_role.permissions.count).to eq(0)
#       end
#     end

#     context "updating with same permission" do
#       let(:updated_name) { nil }
#       let(:updated_description) { nil }
#       let(:updated_permission_ids) { [ create_bookings_permission.id ] }

#       it "keeps the same permission" do
#         custom_role.reload
#         expect(custom_role.permissions.pluck(:id)).to eq([ create_bookings_permission.id ])
#       end
#     end

#     context "updating all attributes at once" do
#       let(:updated_permission_ids) { [ read_courts_permission.id ] }

#       it "updates all attributes successfully" do
#         custom_role.reload
#         expect(custom_role.name).to eq("Updated Role Name")
#         expect(custom_role.description).to eq("Updated description")
#         expect(custom_role.permissions.pluck(:id)).to eq([ read_courts_permission.id ])
#       end
#     end
#   end

#   # FAILURE PATHS
#   context "when authenticated as owner with invalid parameters" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#     context "when name is empty" do
#       let(:updated_name) { "" }

#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "matches error response schema" do
#         expect(response).to match_json_schema("error_response")
#       end

#       it "does not update the role" do
#         custom_role.reload
#         expect(custom_role.name).to eq("Original Name")
#       end
#     end

#     context "when name is blank (whitespace)" do
#       let(:updated_name) { "   " }

#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "does not update the role" do
#         custom_role.reload
#         expect(custom_role.name).to eq("Original Name")
#       end
#     end

#     context "when name already exists (duplicate)" do
#       let!(:other_role) { create(:role, :custom_role) } # Uses sequence for unique name
#       let(:updated_name) { other_role.name }

#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end
#     end

#     context "when permission_ids contain invalid IDs" do
#       let(:updated_name) { nil }
#       let(:updated_description) { nil }
#       let(:updated_permission_ids) { [ 99999 ] }

#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "does not update the permissions" do
#         custom_role.reload
#         expect(custom_role.permissions.pluck(:id)).to eq([ create_bookings_permission.id ])
#       end
#     end
#   end

#   context "when attempting to update a system role" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:role_id) { owner_role.id }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the system role" do
#       owner_role.reload
#       expect(owner_role.name).to eq("Owner")
#     end
#   end

#   context "when role does not exist" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#     let(:role_id) { 99999 }

#     before do
#       delete endpoint, headers: request_headers
#     end

#     it "returns unprocessable entity status" do
#       expect(response).to have_http_status(:unprocessable_entity)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#     end
#   end

#   context "when authenticated as admin (insufficient permissions)" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the role" do
#       custom_role.reload
#       expect(custom_role.name).to eq("Original Name")
#     end
#   end

#   context "when authenticated as receptionist" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the role" do
#       custom_role.reload
#       expect(custom_role.name).to eq("Original Name")
#     end
#   end

#   context "when not authenticated" do
#     let(:request_headers) { headers }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "does not update the role" do
#       custom_role.reload
#       expect(custom_role.name).to eq("Original Name")
#     end
#   end
# end

# # ==================================================
