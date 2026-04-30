# frozen_string_literal: true

module Api::V0
  class CourtsController < ApiController
    skip_before_action :authenticate_user!, only: %i[index show]

    resource_description do
      resource_id "Courts"
      api_versions "v0"
      short "Manage courts within a venue — listing, creation, updates, reordering, and deletion"
      description <<~DESC
        Courts belong to a venue. Creating, updating, reordering, and deleting courts requires
        the authenticated user to have venue-owner or admin permissions for the parent venue.
        Public endpoints (index, show) do not require authentication.
      DESC
    end

    # GET /api/v0/courts
    def index
      result = Api::V0::Courts::ListCourtsOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # GET /api/v0/courts/:id
    def show
      result = Api::V0::Courts::GetCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :POST, "/courts", "Create a new court within a venue"
    header "Authorization", "Bearer <access_token>", required: true
    param :venue_id, Integer, required: true, desc: "ID of the venue this court belongs to"
    param :court_type_id, Integer, required: true, desc: "ID of the court type (e.g. cricket, football)"
    param :name, String, required: true, desc: "Court name"
    param :description, String, required: false, desc: "Optional court description"
    param :slot_interval, Integer, required: false, desc: "Booking slot duration in minutes (default: 60)"
    param :requires_approval, :bool, required: false, desc: "Whether bookings require manual approval (default: true)"
    param :is_active, :bool, required: false, desc: "Whether the court is publicly visible (default: true)"
    returns code: 201, desc: "Court created successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Created court object (detailed view)" do
        property :id, Integer, desc: "Court ID"
        property :name, String, desc: "Court name"
        property :description, String, desc: "Court description"
        property :slot_interval, Integer, desc: "Booking slot duration in minutes"
        property :requires_approval, :bool, desc: "Whether bookings require manual approval"
        property :is_active, :bool, desc: "Whether the court is publicly visible"
        property :city, String, desc: "City inherited from the parent venue"
        property :sport_type_name, String, desc: "Sport type derived from the court type"
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :updated_at, String, desc: "ISO 8601 last-update timestamp"
        property :court_type_id, Integer, desc: "Court type ID"
        property :court_type, Hash, desc: "Embedded court type object" do
          property :id, Integer
          property :name, String
          property :slug, String
          property :description, String
        end
        property :venue_id, Integer, desc: "Parent venue ID"
        property :venue_name, String, desc: "Parent venue name"
        property :venue, Hash, desc: "Embedded parent venue object" do
          property :id, Integer
          property :name, String
          property :slug, String
          property :address, String
          property :city, String
          property :state, String
          property :country, String
          property :postal_code, String
          property :description, String
          property :email, String
          property :phone_number, String
          property :currency, String
          property :timezone, String
          property :is_active, :bool
          property :created_at, String
          property :updated_at, String
        end
        property :images, Array, desc: "Attached court images"
        property :pricing_rules, Array, desc: "Pricing rules for this court"
        property :price_range, Hash, desc: "Derived min/max price across active pricing rules" do
          property :min, Float
          property :max, Float
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user does not have permission to manage this venue"
    error code: 404, desc: "Venue or court type not found"
    error code: 422, desc: "Validation error (e.g. missing required fields, invalid values)"
    # POST /api/v0/courts
    def create
      result = Api::V0::Courts::CreateCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    # PATCH/PUT /api/v0/courts/:id
    def update
      result = Api::V0::Courts::UpdateCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # PATCH /api/v0/courts/:id/reorder
    def reorder
      result = Api::V0::Courts::ReorderCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    # DELETE /api/v0/courts/:id
    def destroy
      result = Api::V0::Courts::DeleteCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end
  end
end
