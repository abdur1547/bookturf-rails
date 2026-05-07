# frozen_string_literal: true

module Api::V0
  class StaffsController < ApiController
    resource_description do
      resource_id "Staffs"
      api_versions "v0"
      short "Manage staff members for a venue — add, list, update, and remove venue staff"
      description <<~DESC
        Staff members are users who have an active venue membership for a specific venue.
        Every staff member is assigned exactly one role that belongs to the same venue.
        Staff management requires the caller to be the venue owner, a super admin, or a staff
        member with the appropriate `users` permission.

        Response — TS Type

        StaffMember/User Type:
          id: number;
          full_name: string;
          email: string;
          phone_number: string | null;
          avatar_url: string | null;
          system_role: "normal" | "super_admin";
          created_at: string;  // ISO 8601
          updated_at: string;  // ISO 8601
      DESC
    end

    # GET /api/v0/staffs
    api :GET, "/staffs", "List all staff members for a venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Returns all users with an active membership at the specified venue.
      Requires the caller to be the venue owner, a super admin, or a staff member
      with the read permission on users for that venue.

      Query Params — TS type

        venue_id: number;  // required
    DESC
    param :venue_id, Integer, required: true, desc: "ID of the venue whose staff to list"
    returns code: 200, desc: "List of staff members" do
      property :success, [ true ]
      property :data, Array, desc: "Array of staff member objects" do
        property :id, Integer
        property :full_name, String
        property :email, String
        property :phone_number, String, desc: "Nullable"
        property :avatar_url, String, desc: "Nullable"
        property :system_role, String, desc: "'normal' or 'super_admin'"
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue not found"
    error code: 422, desc: "Missing venue_id"
    def index
      result = Api::V0::Staffs::ListStaffsOperation.call(params.to_unsafe_h, current_user)
      handle_operation_response(result)
    end

    # GET /api/v0/staffs/:id
    api :GET, "/staffs/:id", "Retrieve a single staff member"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Returns a single staff member who has an active membership at the specified venue.
      Requires the caller to be the venue owner, a super admin, or a staff member
      with the read permission on users for that venue.

      Path Params — TS type

        id: number;  // required — user ID of the staff member

      Query Params — TS type

        venue_id: number;  // required
    DESC
    param :id, Integer, required: true, desc: "User ID of the staff member"
    param :venue_id, Integer, required: true, desc: "ID of the venue the staff member belongs to"
    returns code: 200, desc: "Staff member details" do
      property :success, [ true ]
      property :data, Hash, desc: "Staff member object" do
        property :id, Integer
        property :full_name, String
        property :email, String
        property :phone_number, String, desc: "Nullable"
        property :avatar_url, String, desc: "Nullable"
        property :system_role, String, desc: "'normal' or 'super_admin'"
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue or staff member not found"
    error code: 422, desc: "Missing required params"
    def show
      result = Api::V0::Staffs::GetStaffOperation.call(params.to_unsafe_h, current_user)
      handle_operation_response(result)
    end

    # POST /api/v0/staffs
    api :POST, "/staffs", "Add a new staff member to a venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Creates a new user account (or finds the existing user by email) and adds them as a
      staff member at the specified venue with the given role. A random temporary password
      is generated for new accounts and emailed to the user along with a login link.
      If the user already has an account, they are invited to the venue using their existing
      credentials. Returns 422 if the user is already a member of the venue.

      Requires the caller to be the venue owner, a super admin, or a staff member with
      the create permission on users for that venue.

      Body Params — TS type

        name: string;       // required
        venue_id: number;   // required
        email: string;      // required
        role_id: number;    // required — must belong to the specified venue
    DESC
    param :name, String, required: true, desc: "Full name of the new staff member"
    param :venue_id, Integer, required: true, desc: "ID of the venue to add the staff member to"
    param :email, String, required: true, desc: "Email address for the staff member's login"
    param :role_id, Integer, required: true, desc: "ID of the role to assign (must belong to the venue)"
    returns code: 201, desc: "Staff member created" do
      property :success, [ true ]
      property :data, Hash, desc: "Created staff member object" do
        property :id, Integer
        property :full_name, String
        property :email, String
        property :phone_number, String, desc: "Nullable"
        property :avatar_url, String, desc: "Nullable"
        property :system_role, String, desc: "'normal' or 'super_admin'"
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue not found"
    error code: 422, desc: "Validation error (missing fields, invalid role, already a member)"
    def create
      result = Api::V0::Staffs::CreateStaffOperation.call(params.to_unsafe_h, current_user)
      handle_operation_response(result, :created)
    end

    # PATCH/PUT /api/v0/staffs/:id
    api :PATCH, "/staffs/:id", "Update a staff member"
    api :PUT, "/staffs/:id", "Update a staff member (full)"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Updates a staff member's name, email, and/or assigned role. All body fields except
      `venue_id` are optional — only supplied fields are changed. When `email` is updated,
      an invitation email is sent to the new address. Requires the caller to be the venue
      owner, a super admin, or a staff member with the update permission on users.

      Body Params — TS type

        venue_id: number;   // required
        name?: string;      // optional
        email?: string;     // optional — triggers invitation email to new address
        role_id?: number;   // optional — must belong to the specified venue
    DESC
    param :id, Integer, required: true, desc: "User ID of the staff member to update"
    param :venue_id, Integer, required: true, desc: "ID of the venue the staff member belongs to"
    param :name, String, required: false, desc: "Updated full name"
    param :email, String, required: false, desc: "Updated email address"
    param :role_id, Integer, required: false, desc: "New role ID (must belong to the venue)"
    returns code: 200, desc: "Staff member updated" do
      property :success, [ true ]
      property :data, Hash, desc: "Updated staff member object" do
        property :id, Integer
        property :full_name, String
        property :email, String
        property :phone_number, String, desc: "Nullable"
        property :avatar_url, String, desc: "Nullable"
        property :system_role, String, desc: "'normal' or 'super_admin'"
        property :created_at, String, desc: "ISO 8601"
        property :updated_at, String, desc: "ISO 8601"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue or staff member not found"
    error code: 422, desc: "Validation error (invalid role, duplicate email)"
    def update
      result = Api::V0::Staffs::UpdateStaffOperation.call(params.to_unsafe_h, current_user)
      handle_operation_response(result)
    end

    # DELETE /api/v0/staffs/:id
    api :DELETE, "/staffs/:id", "Remove a staff member from a venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Removes the user's venue membership, revoking their access to the venue. The user
      account is NOT deleted — they can still log in and make bookings. An email is sent
      to the removed staff member notifying them of the change. Requires the caller to be
      the venue owner, a super admin, or a staff member with the delete permission on users.

      Query Params — TS type

        venue_id: number;  // required
    DESC
    param :id, Integer, required: true, desc: "User ID of the staff member to remove"
    param :venue_id, Integer, required: true, desc: "ID of the venue to remove the staff member from"
    returns code: 200, desc: "Staff member removed" do
      property :success, [ true ]
      property :data, Hash do
        property :message, String, desc: "Confirmation message"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue or staff member not found"
    error code: 422, desc: "Missing required params"
    def destroy
      result = Api::V0::Staffs::DeleteStaffOperation.call(params.to_unsafe_h, current_user)
      handle_operation_response(result)
    end
  end
end
