# frozen_string_literal: true

module Api::V0
  class CourtsController < ApiController
    skip_before_action :authenticate_user!, only: %i[show search]

    resource_description do
      resource_id "Courts"
      api_versions "v0"
      short "Manage courts within a venue — listing, creation, updates, reordering, and deletion"
      description <<~DESC
        Courts belong to a venue. Creating, updating and deleting courts requires
        the authenticated user to have venue-owner or admin permissions for the parent venue.
        Public endpoints (index, show) do not require authentication.

        Response — TS Type

        PricingRule type
          id: number;
          venue_id: number;
          court_id: number;
          name: string;
          price_per_hour: number;
          day_of_week: string;          // enum value e.g. 'all_days', 'monday'
          day_name: string;             // human-readable label e.g. 'All Days'
          start_time: string;           // HH:MM
          end_time: string;             // HH:MM
          start_date: string | null;    // ISO 8601
          end_date: string | null;      // ISO 8601
          priority: number;
          is_active: boolean;
          time_range: string;           // formatted e.g. "08:00 AM - 10:00 PM"
          created_at: string;           // ISO 8601
          updated_at: string;           // ISO 8601

        Court type
          id: number;
          name: string;
          description: string | null;
          court_type_id: number;
          venue_id: number;
          slot_interval: number;        // booking slot duration in minutes
          requires_approval: boolean;
          is_active: boolean;
          court_type_name: string | null;
          venue_name: string | null;
          city: string | null;
          price_range: { min: number; max: number };
          images: Array<{ id: number; url: string }>;
          pricing_rules: PricingRule[];
      DESC
    end

    api :GET, "/courts", "List all active + inactive courts for current logged-in user if they are a staff member with view permissions or owner"
    description <<~DESC
      Private endpoint — authentication required. Returns all courts of current user by default.
      Use `is_active` to restrict by active/inactive status. Supports filtering by
      venue, court type, and city, free-text search, sorting by any court column,
      and offset-based pagination.

      Query Params — TS type

        page?: number | null;             // default: 1
        per_page?: number | null;         // default: 10, max: 100
        venue_id?: number | null;
        court_type_id?: number | null;
        city?: string | null;
        is_active?: boolean | null;       // omitting returns all courts
        search?: string | null;           // searches name, description, venue name
        sort?: string | null;             // valid court column name, default: 'name'
        order?: 'asc' | 'desc' | null;   // default: 'asc'
    DESC
    param :venue_id, Integer, required: false, desc: "Filter by parent venue ID"
    param :court_type_id, Integer, required: false, desc: "Filter by court type ID"
    param :city, String, required: false, desc: "Filter by city name of the parent venue"
    param :is_active, :bool, required: false, desc: "Filter by active status; omitting returns all courts"
    param :search, String, required: false, desc: "Search term matched against court name, description, or venue name"
    param :sort, String, required: false, desc: "Column to sort by (must be a valid court column name; defaults to name)"
    param :order, String, required: false, desc: "Sort direction: asc or desc (default: asc)"
    param :page, Integer, required: false, desc: "Page number, must be greater than 0 (default: 1)"
    param :per_page, Integer, required: false, desc: "Results per page, 1–100, must be greater than 0 (default: 10)"
    returns code: 200, desc: "Courts retrieved successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Array, desc: "Array of court objects" do
        property :id, Integer
        property :name, String
        property :description, String, required: false
        property :court_type_id, Integer
        property :venue_id, Integer
        property :slot_interval, Integer, desc: "Booking slot duration in minutes"
        property :requires_approval, :bool
        property :is_active, :bool
        property :court_type_name, String, required: false
        property :venue_name, String, required: false
        property :city, String, required: false
        property :price_range, Hash do
          property :min, Float
          property :max, Float
        end
        property :images, Array do
          property :id, Integer
          property :url, String
        end
        property :pricing_rules, Array, desc: "Pricing rules for this court"
      end
    end
    error code: 422, desc: "Invalid query parameter (e.g. unrecognised sort field, invalid order direction, page or per_page ≤ 0)"
    def index
      result = Api::V0::Courts::ListCourtsOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/courts/search", "Search courts across all venues with optional filters and pagination, public endpoint"
    description <<~DESC
      Public endpoint — no authentication required. Returns all courts by default.
      Use `is_active` to restrict by active/inactive status. Supports filtering by
      venue, court type, and city, free-text search, sorting by any court column,
      and offset-based pagination.

      Query Params — TS type

        page?: number | null;             // default: 1
        per_page?: number | null;         // default: 10, max: 100
        venue_id?: number | null;
        court_type_id?: number | null;
        city?: string | null;
        is_active?: boolean | null;       // omitting returns all courts
        search?: string | null;           // searches name, description, venue name
        sort?: string | null;             // valid court column name, default: 'name'
        order?: 'asc' | 'desc' | null;   // default: 'asc'
    DESC
    param :venue_id, Integer, required: false, desc: "Filter by parent venue ID"
    param :court_type_id, Integer, required: false, desc: "Filter by court type ID"
    param :city, String, required: false, desc: "Filter by city name of the parent venue"
    param :is_active, :bool, required: false, desc: "Filter by active status; omitting returns all courts"
    param :search, String, required: false, desc: "Search term matched against court name, description, or venue name"
    param :sort, String, required: false, desc: "Column to sort by (must be a valid court column name; defaults to name)"
    param :order, String, required: false, desc: "Sort direction: asc or desc (default: asc)"
    param :page, Integer, required: false, desc: "Page number, must be greater than 0 (default: 1)"
    param :per_page, Integer, required: false, desc: "Results per page, 1–100, must be greater than 0 (default: 10)"
    returns code: 200, desc: "Courts retrieved successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Array, desc: "Array of court objects" do
        property :id, Integer
        property :name, String
        property :description, String, required: false
        property :court_type_id, Integer
        property :venue_id, Integer
        property :slot_interval, Integer, desc: "Booking slot duration in minutes"
        property :requires_approval, :bool
        property :is_active, :bool
        property :court_type_name, String, required: false
        property :venue_name, String, required: false
        property :city, String, required: false
        property :price_range, Hash do
          property :min, Float
          property :max, Float
        end
        property :images, Array do
          property :id, Integer
          property :url, String
        end
        property :pricing_rules, Array, desc: "Pricing rules for this court"
      end
    end
    error code: 422, desc: "Invalid query parameter (e.g. unrecognised sort field, invalid order direction, page or per_page ≤ 0)"
    def search
      result = Api::V0::Courts::SearchCourtsOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/courts/:id", "Retrieve a single court by ID"
    description <<~DESC
      Public endpoint — no authentication required. Returns the full detail view of a court.
      Responds with 404 when no court with the given ID exists.
    DESC
    param :id, Integer, required: true, desc: "ID of the court to retrieve"
    returns code: 200, desc: "Court retrieved successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Court object" do
        property :id, Integer
        property :name, String
        property :description, String, required: false
        property :court_type_id, Integer
        property :venue_id, Integer
        property :slot_interval, Integer, desc: "Booking slot duration in minutes"
        property :requires_approval, :bool
        property :is_active, :bool
        property :court_type_name, String, required: false
        property :venue_name, String, required: false
        property :city, String, required: false
        property :price_range, Hash do
          property :min, Float
          property :max, Float
        end
        property :images, Array do
          property :id, Integer
          property :url, String
        end
        property :pricing_rules, Array, desc: "Pricing rules for this court"
      end
    end
    error code: 404, desc: "Court not found"
    def show
      result = Api::V0::Courts::GetCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :POST, "/courts", "Create a new court within a venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Creates a new court under the specified venue. Requires venue-owner or admin permissions.

      Body Params — TS type

        {
          venue_id: number;                // required
          court_type_id: number;           // required
          name: string;                    // required
          description?: string | null;
          slot_interval?: number | null;   // minutes, default: 60
          requires_approval?: boolean | null; // default: false
          is_active?: boolean | null;      // default: true
        }
    DESC
    param :venue_id, Integer, required: true, desc: "ID of the venue this court belongs to"
    param :court_type_id, Integer, required: true, desc: "ID of the court type (e.g. cricket, football)"
    param :name, String, required: true, desc: "Court name"
    param :description, String, required: false, desc: "Optional court description"
    param :slot_interval, Integer, required: false, desc: "Booking slot duration in minutes (default: 60)"
    param :requires_approval, :bool, required: false, desc: "Whether bookings require manual approval (default: false)"
    param :is_active, :bool, required: false, desc: "Whether the court is publicly visible (default: true)"
    returns code: 201, desc: "Court created successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Created court object" do
        property :id, Integer
        property :name, String
        property :description, String, required: false
        property :court_type_id, Integer
        property :venue_id, Integer
        property :slot_interval, Integer
        property :requires_approval, :bool
        property :is_active, :bool
        property :court_type_name, String, required: false
        property :venue_name, String, required: false
        property :city, String, required: false
        property :price_range, Hash do
          property :min, Float
          property :max, Float
        end
        property :images, Array do
          property :id, Integer
          property :url, String
        end
        property :pricing_rules, Array, desc: "Pricing rules for this court"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user does not have permission to manage this venue"
    error code: 404, desc: "Venue or court type not found"
    error code: 422, desc: "Validation error (e.g. missing required fields, invalid values)"
    def create
      result = Api::V0::Courts::CreateCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    api :PATCH, "/courts/:id", "Update an existing court"
    api :PUT, "/courts/:id", "Update an existing court"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Updates an existing court. All body fields are optional — only supplied fields are changed.

      Body Params — TS type

        {
          court_type_id?: number | null;
          name?: string | null;
          description?: string | null;
          slot_interval?: number | null;
          requires_approval?: boolean | null;
          is_active?: boolean | null;
        }
    DESC
    param :id, Integer, required: true, desc: "ID of the court to update"
    param :court_type_id, Integer, required: false, desc: "ID of the court type (e.g. cricket, football)"
    param :name, String, required: false, desc: "Court name"
    param :description, String, required: false, desc: "Court description"
    param :slot_interval, Integer, required: false, desc: "Booking slot duration in minutes"
    param :requires_approval, :bool, required: false, desc: "Whether bookings require manual approval"
    param :is_active, :bool, required: false, desc: "Whether the court is publicly visible"
    returns code: 200, desc: "Court updated successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Updated court object" do
        property :id, Integer
        property :name, String
        property :description, String, required: false
        property :court_type_id, Integer
        property :venue_id, Integer
        property :slot_interval, Integer
        property :requires_approval, :bool
        property :is_active, :bool
        property :court_type_name, String, required: false
        property :venue_name, String, required: false
        property :city, String, required: false
        property :price_range, Hash do
          property :min, Float
          property :max, Float
        end
        property :images, Array do
          property :id, Integer
          property :url, String
        end
        property :pricing_rules, Array, desc: "Pricing rules for this court"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user does not have permission to manage this court"
    error code: 404, desc: "Court not found"
    error code: 422, desc: "Validation error (e.g. invalid values)"
    def update
      result = Api::V0::Courts::UpdateCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :DELETE, "/courts/:id", "Delete a court by ID"
    header "Authorization", "Bearer <access_token>", required: true
    param :id, Integer, required: true, desc: "ID of the court to delete"
    returns code: 200, desc: "Court deleted successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash do
        property :message, String, desc: "Confirmation message"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user does not have permission to manage this court"
    error code: 404, desc: "Court not found"
    def destroy
      result = Api::V0::Courts::DeleteCourtOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end
  end
end
