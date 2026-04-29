# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "DELETE /api/v0/roles/:id", type: :request do
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

#   let(:custom_role) { create(:role, :custom_role, name: "Role to Delete") }
#   let(:role_id) { custom_role.id }
#   let(:endpoint) { "/api/v0/roles/#{role_id}" }
#   let(:request_headers) { headers }

#   # SUCCESS PATHS
#   context "when authenticated as owner" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#       context "deleting a custom role with no users" do
#         before do
#           custom_role # Ensure role exists
#           delete endpoint, headers: request_headers
#         end

#         it "returns success response" do
#           expect(response).to have_http_status(:ok)
#         end

#         it "matches the destroy response schema" do
#           expect(response).to match_json_schema("roles/destroy_response")
#         end

#         it "deletes the role from database" do
#           expect(Role.find_by(id: custom_role.id)).to be_nil
#         end

#         it "returns success message" do
#           data = response.parsed_body["data"]
#           expect(data["message"]).to eq("Role deleted successfully")
#         end
#       end

#       context "deleting a custom role with permissions but no users" do
#         before do
#           custom_role.add_permission(create_bookings_permission)
#           custom_role.add_permission(read_bookings_permission)
#           delete endpoint, headers: request_headers
#         end

#         it "deletes the role successfully" do
#           expect(response).to have_http_status(:ok)
#         end

#         it "removes the role from database" do
#           expect(Role.find_by(id: custom_role.id)).to be_nil
#         end
#       end
#     end

#     # FAILURE PATHS
#     context "when attempting to delete a role with assigned users" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#       let(:assigned_user) { create(:user, email: "assigned@example.com") }

#       before do
#         assigned_user.assign_role(custom_role)
#         delete endpoint, headers: request_headers
#       end

#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "matches error response schema" do
#         expect(response).to match_json_schema("error_response")
#       end

#       it "includes appropriate error message" do
#         errors = response.parsed_body["errors"]
#         error_text = errors.is_a?(Hash) ? errors["error"] : errors
#         expect(error_text).to match(/Cannot delete role with assigned users/i)
#       end

#       it "does not delete the role" do
#         expect(Role.find_by(id: custom_role.id)).to be_present
#       end

#       it "keeps the role-user association intact" do
#         custom_role.reload
#         expect(custom_role.users.count).to eq(1)
#       end
#     end

#     context "when attempting to delete a system role" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#       let(:role_id) { owner_role.id }

#       before do
#         delete endpoint, headers: request_headers
#       end


#       it "returns forbidden status" do
#         expect(response).to have_http_status(:forbidden)
#       end

#       it "does not delete the system role" do
#         expect(Role.find_by(id: owner_role.id)).to be_present
#       end
#     end

#     context "when role does not exist" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#       let(:role_id) { 99999 }

#       before do
#         delete endpoint, headers: request_headers
#       end

#       before do
#         delete endpoint, headers: request_headers
#       end


#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end

#       it "returns error response" do
#         expect(response.parsed_body["success"]).to be false
#       end
#     end

#     context "when role_id is invalid format" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
#       let(:role_id) { "invalid-id" }

#       before do
#         delete endpoint, headers: request_headers
#       end


#       it "returns unprocessable entity status" do
#         expect(response).to have_http_status(:unprocessable_entity)
#       end
#     end

#     context "when authenticated as admin (insufficient permissions)" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

#       before do
#         custom_role # Ensure role exists
#         delete endpoint, headers: request_headers
#       end

#       it "returns forbidden status" do
#         expect(response).to have_http_status(:forbidden)
#       end

#       it "does not delete the role" do
#         expect(Role.find_by(id: custom_role.id)).to be_present
#       end
#     end

#     context "when authenticated as receptionist" do
#       let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

#       before do
#         custom_role # Ensure role exists
#         delete endpoint, headers: request_headers
#       end

#       it "returns forbidden status" do
#         expect(response).to have_http_status(:forbidden)
#       end

#       it "does not delete the role" do
#         expect(Role.find_by(id: custom_role.id)).to be_present
#       end
#     end

#     context "when not authenticated" do
#       let(:request_headers) { headers }

#       before do
#         custom_role # Ensure role exists
#         delete endpoint, headers: request_headers
#       end

#       it "returns forbidden status" do
#         expect(response).to have_http_status(:forbidden)
#       end

#       it "does not delete the role" do
#         expect(Role.find_by(id: custom_role.id)).to be_present
#       end
#     end

#     context "when authenticated with invalid token" do
#       let(:request_headers) { headers.merge("Authorization" => "Bearer invalid_token") }

#       before do
#         custom_role # Ensure role exists
#         delete endpoint, headers: request_headers
#       end

#       it "returns unauthorized status" do
#         expect(response).to have_http_status(:forbidden)
#       end

#       it "does not delete the role" do
#         expect(Role.find_by(id: custom_role.id)).to be_present
#       end
#     end
#   end
