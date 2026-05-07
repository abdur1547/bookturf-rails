# frozen_string_literal: true

module Api::V0
  class RolesController < ApiController
    resource_description do
      resource_id "Roles"
      api_versions "v0"
      short "Manage custom roles for a venue — create, list, update, and delete venue-scoped roles"
      description <<~DESC
        Roles are venue-scoped. Every role belongs to exactly one venue and can only be managed
        by the venue owner, a super admin, or a staff member with the appropriate roles permission.

        Response — TS Type

        Permsission Type:
          id: number;
          resource: string;
          action: string;
        Role Type:
          id: number;
          name: string;
          venue_id: number;
          created_at: string;  // ISO 8601
          updated_at: string;  // ISO 8601
          permissions: Permission[];
      DESC
    end

    # GET /api/v0/roles
    api :GET, "/roles", "List all roles for a venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Returns all roles belonging to the specified venue, sorted alphabetically.
      Requires the caller to be the venue owner, a super admin, or a staff member
      with the read permission on roles for that venue.

      Query Params — TS type

        venue_id: number;  // required
    DESC
    param :venue_id, Integer, required: true, desc: "ID of the venue whose roles to list"
    returns code: 200, desc: "List of roles" do
      property :success, [ true ]
      property :data, Array, desc: "Array of role objects" do
        property :id, Integer
        property :name, String
        property :venue_id, Integer
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
        property :permissions, Array do
          property :id, Integer
          property :resource, String
          property :action, String
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue not found"
    error code: 422, desc: "Missing venue_id"
    def index
      result = Api::V0::Roles::ListRolesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # GET /api/v0/roles/:id
    api :GET, "/roles/:id", "Retrieve a single role by ID"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Returns a single role with its permissions. Requires the caller to be the venue
      owner, a super admin, or a staff member with the read permission on roles.

      Path Params — TS type

        id: number;  // required — role ID
    DESC
    param :id, Integer, required: true, desc: "Role ID"
    returns code: 200, desc: "Role details" do
      property :success, [ true ]
      property :data, Hash, desc: "Role object" do
        property :id, Integer
        property :name, String
        property :venue_id, Integer
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
        property :permissions, Array do
          property :id, Integer
          property :resource, String
          property :action, String
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Role not found"
    def show
      result = Api::V0::Roles::GetRoleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # POST /api/v0/roles
    api :POST, "/roles", "Create a new role for a venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Creates a new custom role scoped to the specified venue and assigns the given permissions.
      Requires the caller to be the venue owner, a super admin, or a staff member with the
      create permission on roles.

      Body Params — TS type

        name: string;              // required
        venue_id: number;          // required
        permission_ids: number[];  // required — pass empty array for no permissions
    DESC
    param :name, String, required: true, desc: "Role name (unique within the venue)"
    param :venue_id, Integer, required: true, desc: "ID of the venue this role belongs to"
    param :permission_ids, Array, required: true, desc: "IDs of permissions to assign (can be empty)"
    returns code: 201, desc: "Role created" do
      property :success, [ true ]
      property :data, Hash, desc: "Created role object" do
        property :id, Integer
        property :name, String
        property :venue_id, Integer
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
        property :permissions, Array do
          property :id, Integer
          property :resource, String
          property :action, String
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue not found"
    error code: 422, desc: "Validation error (blank name, duplicate name, invalid permission IDs)"
    def create
      result = Api::V0::Roles::CreateRoleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    # PATCH/PUT /api/v0/roles/:id
    api :PATCH, "/roles/:id", "Update an existing role"
    api :PUT, "/roles/:id", "Update an existing role (full)"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Updates a role's name and/or permissions. All body fields are optional — only supplied
      fields are changed. Requires the caller to be the venue owner, a super admin, or a staff
      member with the update permission on roles.

      When permission_ids is provided, the role's permissions are fully replaced (sync).
      Pass an empty array to remove all permissions.

      Body Params — TS type

        name?: string;              // optional — new role name
        permission_ids?: number[];  // optional — replaces all permissions when provided
    DESC
    param :id, Integer, required: true, desc: "Role ID"
    param :name, String, required: false, desc: "New role name (must be unique within the venue)"
    param :permission_ids, Array, required: false, desc: "New permission set — replaces existing permissions when provided"
    returns code: 200, desc: "Updated role" do
      property :success, [ true ]
      property :data, Hash, desc: "Updated role object" do
        property :id, Integer
        property :name, String
        property :venue_id, Integer
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
        property :permissions, Array do
          property :id, Integer
          property :resource, String
          property :action, String
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Role not found"
    error code: 422, desc: "Validation error (blank name, duplicate name, invalid permission IDs)"
    def update
      result = Api::V0::Roles::UpdateRoleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # DELETE /api/v0/roles/:id
    api :DELETE, "/roles/:id", "Delete a role"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Deletes a role. Roles that still have active venue memberships (assigned users) cannot
      be deleted. Requires the caller to be the venue owner, a super admin, or a staff member
      with the delete permission on roles.

      Path Params — TS type

        id: number;  // required — role ID
    DESC
    param :id, Integer, required: true, desc: "Role ID"
    returns code: 200, desc: "Role deleted" do
      property :success, [ true ]
      property :data, Hash do
        property :message, String, desc: "Confirmation message"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Role not found"
    error code: 422, desc: "Role has active memberships and cannot be deleted"
    def destroy
      result = Api::V0::Roles::DeleteRoleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end
  end
end
