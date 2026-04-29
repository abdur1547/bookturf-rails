# # frozen_string_literal: true

# require 'rails_helper'

# RSpec.describe "GET /api/v0/roles", type: :request do
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

#   let(:endpoint) { "/api/v0/roles" }
#   let(:query_params) { {} }
#   let(:request_headers) { headers }
#   let!(:custom_role1) { create(:role, :custom_role, name: "Court Manager") }
#   let!(:custom_role2) { create(:role, :custom_role, name: "Booking Manager") }

#   before do
#     params_string = query_params.present? ? "?#{query_params.to_query}" : ""
#     get "#{endpoint}#{params_string}", headers: request_headers
#   end

#   # SUCCESS PATHS
#   context "when authenticated as owner" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "matches the index response schema" do
#       expect(response).to match_json_schema("roles/index_response")
#     end

#     it "returns all roles (system + custom)" do
#       data = response.parsed_body["data"]
#       expect(data.length).to be >= 6  # 4 system roles + 2 custom roles
#     end

#     it "includes complete role attributes in response" do
#       role_data = response.parsed_body["data"].first
#       expect(role_data).to include(
#         "id" => be_a(Integer),
#         "name" => be_a(String),
#         "slug" => be_a(String),
#         "description" => be_a(String),
#         "is_custom" => be_in([ true, false ]),
#         "permissions_count" => be_a(Integer),
#         "users_count" => be_a(Integer),
#         "created_at" => be_a(String)
#       )
#     end

#     context "with type=system filter" do
#       let(:query_params) { { type: "system" } }

#       it "returns only system roles" do
#         data = response.parsed_body["data"]
#         expect(data).to all(include("is_custom" => false))
#       end

#       it "excludes custom roles" do
#         data = response.parsed_body["data"]
#         expect(data.none? { |r| r["is_custom"] == true }).to be true
#       end
#     end

#     context "with type=custom filter" do
#       let(:query_params) { { type: "custom" } }

#       it "returns only custom roles" do
#         data = response.parsed_body["data"]
#         expect(data).to all(include("is_custom" => true))
#       end

#       it "excludes system roles" do
#         data = response.parsed_body["data"]
#         expect(data.none? { |r| r["is_custom"] == false }).to be true
#       end
#     end

#     context "with sort=name parameter" do
#       let(:query_params) { { sort: "name" } }

#       it "sorts roles by name alphabetically" do
#         data = response.parsed_body["data"]
#         names = data.map { |r| r["name"] }
#         expect(names).to eq(names.sort)
#       end
#     end

#     context "with sort=created_at parameter" do
#       let(:query_params) { { sort: "created_at" } }

#       it "returns success response" do
#         expect(response).to have_http_status(:ok)
#       end
#     end

#     context "with invalid type parameter" do
#       let(:query_params) { { type: "invalid_type" } }

#       it "returns all roles (ignores invalid filter)" do
#         data = response.parsed_body["data"]
#         expect(data.length).to be >= 6
#       end
#     end
#   end

#   context "when authenticated as admin" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "returns all roles" do
#       data = response.parsed_body["data"]
#       expect(data.length).to be >= 6
#     end

#     it "matches the index response schema" do
#       expect(response).to match_json_schema("roles/index_response")
#     end
#   end

#   context "when authenticated as receptionist" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

#     it "returns success response" do
#       expect(response).to have_http_status(:ok)
#     end

#     it "returns roles data" do
#       expect(response.parsed_body["data"]).to be_an(Array)
#     end
#   end

#   # FAILURE PATHS
#   context "when authenticated as customer (insufficient permissions)" do
#     let(:request_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "matches the error response schema" do
#       expect(response).to match_json_schema("error_response")
#     end

#     it "includes authorization error message" do
#       expect(response.parsed_body["errors"]).to include(
#         match(/not authorized/i)
#       )
#     end
#   end

#   context "when not authenticated (missing token)" do
#     let(:request_headers) { headers }

#     it "returns forbidden status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "matches the error response schema" do
#       expect(response).to match_json_schema("error_response")
#     end
#   end

#   context "when authenticated with invalid token" do
#     let(:request_headers) { headers.merge("Authorization" => "Bearer invalid_token_12345") }

#     it "returns unauthorized status" do
#       expect(response).to have_http_status(:forbidden)
#     end

#     it "returns error response" do
#       expect(response.parsed_body["success"]).to be false
#     end
#   end

#   context "when authenticated with expired token" do
#     let(:expired_token) do
#       payload = { user_id: owner_user.id, exp: 1.hour.ago.to_i }
#       JWT.encode(payload, Rails.application.credentials.secret_key_base, 'HS256')
#     end
#     let(:request_headers) { headers.merge("Authorization" => "Bearer #{expired_token}") }

#     it "returns unauthorized status" do
#       expect(response).to have_http_status(:forbidden)
#     end
#   end
# end
