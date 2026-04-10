# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Api::V0::Roles", type: :request do
  let(:headers) { { "Content-Type" => "application/json" } }

  # Create users with different roles
  let(:owner_role) { create(:role, :owner) }
  let(:admin_role) { create(:role, :admin) }
  let(:receptionist_role) { create(:role, :receptionist) }
  let(:customer_role) { create(:role, :customer) }

  let(:owner_user) { create(:user) }
  let(:admin_user) { create(:user) }
  let(:receptionist_user) { create(:user) }
  let(:customer_user) { create(:user) }

  # Create permissions for testing
  let(:create_bookings_permission) { create(:permission, :create_bookings) }
  let(:read_bookings_permission) { create(:permission, :read_bookings) }
  let(:manage_bookings_permission) { create(:permission, :manage_bookings) }
  let(:read_courts_permission) { create(:permission, :read_courts) }

  before do
    # Assign roles to users
    owner_user.assign_role(owner_role)
    admin_user.assign_role(admin_role)
    receptionist_user.assign_role(receptionist_role)
    customer_user.assign_role(customer_role)
  end

  # Helper method to generate auth token
  def auth_token_for(user)
    result = Jwt::Issuer.call(user)
    token_data = result.data
    "Bearer #{token_data[:access_token]}"
  end

  describe "GET /api/v0/roles" do
    let(:endpoint) { "/api/v0/roles" }
    let!(:custom_role1) { create(:role, :custom_role, name: "Court Manager") }
    let!(:custom_role2) { create(:role, :custom_role, name: "Booking Manager") }

    context "when authenticated as owner" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

      it "returns success response" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it "returns all roles (system + custom)" do
        get endpoint, headers: auth_headers
        data = response.parsed_body["data"]
        expect(data).to be_an(Array)
        expect(data.length).to be >= 6  # 4 system roles + 2 custom roles
      end

      it "includes role attributes" do
        get endpoint, headers: auth_headers
        role_data = response.parsed_body["data"].first
        expect(role_data).to include(
          "id",
          "name",
          "slug",
          "description",
          "is_custom",
          "permissions_count",
          "users_count",
          "created_at"
        )
      end

      context "with type filter" do
        it "returns only system roles when type=system" do
          get "#{endpoint}?type=system", headers: auth_headers
          data = response.parsed_body["data"]
          expect(data.all? { |r| r["is_custom"] == false }).to be true
        end

        it "returns only custom roles when type=custom" do
          get "#{endpoint}?type=custom", headers: auth_headers
          data = response.parsed_body["data"]
          expect(data.all? { |r| r["is_custom"] == true }).to be true
        end
      end

      context "with sort parameter" do
        it "sorts by name" do
          get "#{endpoint}?sort=name", headers: auth_headers
          data = response.parsed_body["data"]
          names = data.map { |r| r["name"] }
          expect(names).to eq(names.sort)
        end

        it "sorts by created_at" do
          get "#{endpoint}?sort=created_at", headers: auth_headers
          expect(response).to have_http_status(:ok)
        end
      end
    end

    context "when authenticated as admin" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

      it "returns success response" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it "returns all roles" do
        get endpoint, headers: auth_headers
        data = response.parsed_body["data"]
        expect(data).to be_an(Array)
        expect(data.length).to be >= 6
      end
    end

    context "when authenticated as receptionist" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

      it "returns success response" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as customer" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(customer_user)) }

      it "returns forbidden" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns unauthorized" do
        get endpoint, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET /api/v0/roles/:id" do
    let(:role) { create(:role, :custom_role, name: "Test Role") }
    let(:endpoint) { "/api/v0/roles/#{role.id}" }

    before do
      # Add permissions to the role
      role.add_permission(create_bookings_permission)
      role.add_permission(read_bookings_permission)

      # Add a user to the role
      test_user = create(:user)
      test_user.assign_role(role)
    end

    context "when authenticated as owner" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

      it "returns success response" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:ok)
      end

      it "returns role details" do
        get endpoint, headers: auth_headers
        data = response.parsed_body["data"]
        expect(data).to include(
          "id" => role.id,
          "name" => "Test Role",
          "slug" => role.slug,
          "is_custom" => true
        )
      end

      it "includes associated permissions" do
        get endpoint, headers: auth_headers
        data = response.parsed_body["data"]
        expect(data["permissions"]).to be_an(Array)
        expect(data["permissions"].length).to eq(2)
        expect(data["permissions"].first).to include("id", "name", "resource", "action")
      end

      it "includes associated users" do
        get endpoint, headers: auth_headers
        data = response.parsed_body["data"]
        expect(data["users"]).to be_an(Array)
        expect(data["users"].length).to eq(1)
        expect(data["users"].first).to include("id", "name")
      end
    end

    context "when authenticated as admin" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

      it "returns success response" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as receptionist" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(receptionist_user)) }

      it "returns forbidden" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when role does not exist" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
      let(:endpoint) { "/api/v0/roles/99999" }

      it "returns not found" do
        get endpoint, headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end

      it "includes error message" do
        get endpoint, headers: auth_headers
        expect(response.parsed_body["success"]).to be false
        expect(response.parsed_body["errors"]).to be_present
      end
    end
  end

  describe "POST /api/v0/roles" do
    let(:endpoint) { "/api/v0/roles" }

    context "when authenticated as owner" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

      context "with valid parameters" do
        let(:valid_params) do
          {
            role: {
              name: "New Custom Role",
              description: "A newly created custom role",
              permission_ids: [ create_bookings_permission.id, read_bookings_permission.id ]
            }
          }
        end

        it "returns created status" do
          post endpoint, params: valid_params.to_json, headers: auth_headers
          expect(response).to have_http_status(:created)
        end

        it "creates a new role" do
          expect {
            post endpoint, params: valid_params.to_json, headers: auth_headers
          }.to change(Role, :count).by(1)
        end

        it "creates a custom role" do
          post endpoint, params: valid_params.to_json, headers: auth_headers
          new_role = Role.last
          expect(new_role.is_custom).to be true
        end

        it "returns the created role" do
          post endpoint, params: valid_params.to_json, headers: auth_headers
          data = response.parsed_body["data"]
          expect(data).to include(
            "name" => "New Custom Role",
            "description" => "A newly created custom role",
            "is_custom" => true
          )
        end

        it "assigns permissions to the role" do
          post endpoint, params: valid_params.to_json, headers: auth_headers
          new_role = Role.last
          expect(new_role.permissions.count).to eq(2)
          expect(new_role.permissions.pluck(:id)).to match_array([
            create_bookings_permission.id,
            read_bookings_permission.id
          ])
        end

        it "generates a slug from name" do
          post endpoint, params: valid_params.to_json, headers: auth_headers
          new_role = Role.last
          expect(new_role.slug).to eq("new_custom_role")
        end
      end

      context "with valid parameters but no permissions" do
        let(:valid_params) do
          {
            role: {
              name: "Role Without Permissions",
              description: "A role without initial permissions"
            }
          }
        end

        it "creates the role successfully" do
          expect {
            post endpoint, params: valid_params.to_json, headers: auth_headers
          }.to change(Role, :count).by(1)
        end

        it "has no permissions" do
          post endpoint, params: valid_params.to_json, headers: auth_headers
          new_role = Role.last
          expect(new_role.permissions.count).to eq(0)
        end
      end

      context "with invalid parameters" do
        context "when name is missing" do
          let(:invalid_params) do
            {
              role: {
                description: "Role without name"
              }
            }
          end

          it "returns unprocessable entity" do
            post endpoint, params: invalid_params.to_json, headers: auth_headers
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "includes validation errors" do
            post endpoint, params: invalid_params.to_json, headers: auth_headers
            expect(response.parsed_body["success"]).to be false
            expect(response.parsed_body["errors"]).to be_present
          end

          it "does not create a role" do
            expect {
              post endpoint, params: invalid_params.to_json, headers: auth_headers
            }.not_to change(Role, :count)
          end
        end

        context "when name already exists" do
          let!(:existing_role) { create(:role, name: "Existing Role") }
          let(:invalid_params) do
            {
              role: {
                name: "Existing Role"
              }
            }
          end

          it "returns unprocessable entity" do
            post endpoint, params: invalid_params.to_json, headers: auth_headers
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "does not create a duplicate role" do
            expect {
              post endpoint, params: invalid_params.to_json, headers: auth_headers
            }.not_to change(Role, :count)
          end
        end

        context "when permission_ids contain invalid IDs" do
          let(:invalid_params) do
            {
              role: {
                name: "Role With Invalid Permissions",
                permission_ids: [ 99999, 88888 ]
              }
            }
          end

          it "returns unprocessable entity" do
            post endpoint, params: invalid_params.to_json, headers: auth_headers
            expect(response).to have_http_status(:unprocessable_entity)
          end
        end
      end
    end

    context "when authenticated as admin" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }
      let(:valid_params) do
        {
          role: {
            name: "New Role by Admin"
          }
        }
      end

      it "returns forbidden" do
        post endpoint, params: valid_params.to_json, headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "does not create a role" do
        expect {
          post endpoint, params: valid_params.to_json, headers: auth_headers
        }.not_to change(Role, :count)
      end
    end

    context "when not authenticated" do
      let(:valid_params) do
        {
          role: {
            name: "Unauthenticated Role"
          }
        }
      end

      it "returns forbidden" do
        post endpoint, params: valid_params.to_json, headers: headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "PATCH /api/v0/roles/:id" do
    let(:custom_role) { create(:role, :custom_role, name: "Original Name", description: "Original description") }
    let(:endpoint) { "/api/v0/roles/#{custom_role.id}" }

    before do
      custom_role.add_permission(create_bookings_permission)
    end

    context "when authenticated as owner" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

      context "updating a custom role" do
        context "with valid parameters" do
          let(:update_params) do
            {
              role: {
                name: "Updated Role Name",
                description: "Updated description"
              }
            }
          end

          it "returns success response" do
            patch endpoint, params: update_params.to_json, headers: auth_headers
            expect(response).to have_http_status(:ok)
          end

          it "updates the role attributes" do
            patch endpoint, params: update_params.to_json, headers: auth_headers
            custom_role.reload
            expect(custom_role.name).to eq("Updated Role Name")
            expect(custom_role.description).to eq("Updated description")
          end

          it "updates the slug based on new name" do
            patch endpoint, params: update_params.to_json, headers: auth_headers
            custom_role.reload
            expect(custom_role.slug).to eq("updated_role_name")
          end

          it "returns the updated role" do
            patch endpoint, params: update_params.to_json, headers: auth_headers
            data = response.parsed_body["data"]
            expect(data["name"]).to eq("Updated Role Name")
            expect(data["description"]).to eq("Updated description")
          end
        end

        context "updating permissions" do
          let(:update_params) do
            {
              role: {
                permission_ids: [ read_bookings_permission.id, manage_bookings_permission.id ]
              }
            }
          end

          it "syncs the permissions" do
            patch endpoint, params: update_params.to_json, headers: auth_headers
            custom_role.reload
            expect(custom_role.permissions.pluck(:id)).to match_array([
              read_bookings_permission.id,
              manage_bookings_permission.id
            ])
          end

          it "removes old permissions not in the list" do
            patch endpoint, params: update_params.to_json, headers: auth_headers
            custom_role.reload
            expect(custom_role.has_permission?(create_bookings_permission.name)).to be false
          end
        end

        context "with invalid parameters" do
          let(:invalid_params) do
            {
              role: {
                name: ""
              }
            }
          end

          it "returns unprocessable entity" do
            patch endpoint, params: invalid_params.to_json, headers: auth_headers
            expect(response).to have_http_status(:unprocessable_entity)
          end

          it "does not update the role" do
            expect {
              patch endpoint, params: invalid_params.to_json, headers: auth_headers
              custom_role.reload
            }.not_to change(custom_role, :name)
          end
        end
      end

      context "attempting to update a system role" do
        let(:system_role_endpoint) { "/api/v0/roles/#{owner_role.id}" }
        let(:update_params) do
          {
            role: {
              name: "Updated System Role"
            }
          }
        end

        it "returns forbidden" do
          patch system_role_endpoint, params: update_params.to_json, headers: auth_headers
          expect(response).to have_http_status(:forbidden)
        end

        it "does not update the system role" do
          expect {
            patch system_role_endpoint, params: update_params.to_json, headers: auth_headers
            owner_role.reload
          }.not_to change(owner_role, :name)
        end
      end
    end

    context "when authenticated as admin" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }
      let(:update_params) do
        {
          role: {
            name: "Admin Update Attempt"
          }
        }
      end

      it "returns forbidden" do
        patch endpoint, params: update_params.to_json, headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE /api/v0/roles/:id" do
    let(:custom_role) { create(:role, :custom_role, name: "Role to Delete") }
    let(:endpoint) { "/api/v0/roles/#{custom_role.id}" }

    context "when authenticated as owner" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

      context "deleting a custom role with no users" do
        it "returns success response" do
          delete endpoint, headers: auth_headers
          expect(response).to have_http_status(:ok)
        end

        it "deletes the role" do
          custom_role  # Ensure role exists
          expect {
            delete endpoint, headers: auth_headers
          }.to change(Role, :count).by(-1)
        end

        it "returns success message" do
          delete endpoint, headers: auth_headers
          data = response.parsed_body["data"]
          expect(data["message"]).to eq("Role deleted successfully")
        end
      end

      context "attempting to delete a role with assigned users" do
        before do
          test_user = create(:user)
          test_user.assign_role(custom_role)
        end

        it "returns unprocessable entity" do
          delete endpoint, headers: auth_headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "does not delete the role" do
          expect {
            delete endpoint, headers: auth_headers
          }.not_to change(Role, :count)
        end

        it "includes error message" do
          delete endpoint, headers: auth_headers
          body = response.parsed_body
          expect(body["success"]).to be false
          # Controller wraps errors in either "errors" or "error" key
          error_msg = body["errors"]
          if error_msg.is_a?(Hash)
            expect(error_msg["error"]).to eq("Cannot delete role with assigned users")
          else
            expect(error_msg).to eq("Cannot delete role with assigned users")
          end
        end
      end

      context "attempting to delete a system role" do
        let(:system_role_endpoint) { "/api/v0/roles/#{owner_role.id}" }

        it "returns forbidden" do
          delete system_role_endpoint, headers: auth_headers
          expect(response).to have_http_status(:forbidden)
        end

        it "does not delete the system role" do
          owner_role  # Ensure role exists
          expect {
            delete system_role_endpoint, headers: auth_headers
          }.not_to change(Role, :count)
        end
      end
    end

    context "when authenticated as admin" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(admin_user)) }

      it "returns forbidden" do
        delete endpoint, headers: auth_headers
        expect(response).to have_http_status(:forbidden)
      end

      it "does not delete the role" do
        custom_role  # Ensure role exists
        expect {
          delete endpoint, headers: auth_headers
        }.not_to change(Role, :count)
      end
    end

    context "when role does not exist" do
      let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }
      let(:endpoint) { "/api/v0/roles/99999" }

      it "returns not found" do
        delete endpoint, headers: auth_headers
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  # Additional edge cases
  describe "Edge Cases" do
    let(:auth_headers) { headers.merge("Authorization" => auth_token_for(owner_user)) }

    context "when creating a role with empty permission_ids array" do
      let(:params) do
        {
          role: {
            name: "Role With Empty Permissions",
            permission_ids: []
          }
        }
      end

      it "creates the role successfully" do
        post "/api/v0/roles", params: params.to_json, headers: auth_headers
        expect(response).to have_http_status(:created)
        expect(Role.last.permissions.count).to eq(0)
      end
    end

    context "when updating role with duplicate permission_ids" do
      let(:custom_role) { create(:role, :custom_role) }
      let(:params) do
        {
          role: {
            permission_ids: [
              create_bookings_permission.id,
              create_bookings_permission.id,  # Duplicate
              read_bookings_permission.id
            ]
          }
        }
      end

      it "handles duplicates gracefully" do
        patch "/api/v0/roles/#{custom_role.id}", params: params.to_json, headers: auth_headers
        expect(response).to have_http_status(:ok)
        custom_role.reload
        expect(custom_role.permissions.count).to eq(2)  # Not 3
      end
    end
  end
end
