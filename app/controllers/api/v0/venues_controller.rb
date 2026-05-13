# frozen_string_literal: true

module Api::V0
  class VenuesController < ApiController
    skip_before_action :authenticate_user!, only: [ :search, :show, :availability ]

    resource_description do
      resource_id "Venues"
      api_versions "v0"
      short "Manage sports venues — listing, creation, updates, availability, and onboarding"
      description <<~DESC
        Venues are the core resource of Bookturf. A venue owner can create and manage venues,
        including their courts, operating hours, and onboarding progress.
        Public endpoints (index, show, availability) do not require authentication.

        Response — TS Type

        VenueOperatingHour type
          id: number;
          venue_id: number;
          day_of_week: number;     // 0 = Monday … 6 = Sunday
          day_name: string;
          opens_at: string;        // ISO 8601 — null when is_open_24h is true
          closes_at: string;       // ISO 8601 — null when is_open_24h is true
          formatted_hours: string; // e.g. "08:00 AM - 10:00 PM", "Closed", or "Open 24 Hours"
          is_closed: boolean;
          is_open_24h: boolean;

        Venue type
          id: number;
          slug: string;
          name: string;
          address: string;
          city: string;
          state: string;
          country: string;
          postal_code: string | null;
          description: string | null;
          phone_number: string | null;
          email: string | null;
          latitude: number | null;
          longitude: number | null;
          google_maps_url: string | null;
          timezone: string;        // default: 'Asia/Karachi'
          currency: string;        // default: 'PKR'
          is_active: boolean;
          courts_count: number;
          created_at: string;      // ISO 8601
          venue_operating_hours: VenueOperatingHour[];
      DESC
    end

    api :GET, "/venues", "List all active + inactive venues for current logged-in weather user is staff member with view permissions or owner"
    description <<~DESC
      Returns a paginated list of venues. Defaults to all active + inactive venues.

      Query Params — TS type

        page?: number | null;             // default: 1
        per_page?: number | null;         // default: 50
        city?: string | null;
        state?: string | null;
        country?: string | null;
        is_active?: boolean | null;       // default: null (no filter, return both active and inactive)
        search?: string | null;           // searches name, address, city, description
        sort_by?:
          | 'id' | 'address' | 'city' | 'country' | 'created_at' | 'currency'
          | 'description' | 'email' | 'is_active' | 'latitude' | 'longitude'
          | 'name' | 'owner_id' | 'phone_number' | 'postal_code' | 'qr_code_url'
          | 'slug' | 'state' | 'timezone' | 'updated_at'
          | null;                         // default: 'name'
        sort_direction?: 'asc' | 'ASC' | 'desc' | 'DESC' | null; // default: 'asc'
    DESC
    param :page, Integer, required: false, desc: "Page number (default: 1)"
    param :per_page, Integer, required: false, desc: "Results per page, max 100 (default: 10)"
    param :city, String, required: false, desc: "Filter by city (exact match)"
    param :state, String, required: false, desc: "Filter by state (exact match)"
    param :country, String, required: false, desc: "Filter by country (exact match)"
    param :is_active, :bool, required: false, desc: "Filter by active status (default: null)"
    param :search, String, required: false, desc: "Full-text search across name, address, city, description"
    param :sort, %w[name city created_at], required: false, desc: "Sort field (default: name)"
    param :order, %w[asc desc], required: false, desc: "Sort direction (default: asc)"
    returns code: 200, desc: "List of venues" do
      property :success, [ true ]
      property :data, Array, desc: "Array of venue objects (list view)" do
        property :id, Integer
        property :name, String
        property :slug, String
        property :description, String, required: false
        property :address, String
        property :city, String
        property :state, String
        property :country, String
        property :postal_code, String, required: false
        property :phone_number, String, required: false
        property :email, String, required: false
        property :timezone, String, required: false, description: "default to 'Asia/Karachi'"
        property :currency, String, required: false, description: "default to 'PKR'"
        property :is_active, :bool, required: false, description: "Whether the venue is publicly visible, default: true"
        property :latitude, Float, required: false
        property :longitude, Float, required: false
        property :google_maps_url, String, required: false, description: "if lat/lng are present, a Google Maps link is generated"
        property :courts_count, Integer
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :venue_operating_hours, Array, desc: "Operating hours for each day of the week" do
          property :id, Integer
          property :venue_id, Integer
          property :day_of_week, Integer, desc: "0 = Monday … 6 = Sunday"
          property :day_name, String, desc: "Full day name (e.g. Monday)"
          property :opens_at, String, desc: "Opening time"
          property :closes_at, String, desc: "Closing time"
          property :formatted_hours, String, desc: "Human-readable range or 'Closed'"
          property :is_closed, :bool
        end
      end
    end
    def index
      result = Api::V0::Venues::ListVenuesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/venues/search", "List all active venues, public endpoint, no authentication required"
    description <<~DESC
      Returns a paginated list of venues visible to the public. Defaults to active venues only. No authentication required.

      Query Params — TS type

        page?: number | null;             // default: 1
        per_page?: number | null;         // default: 50
        city?: string | null;
        state?: string | null;
        country?: string | null;
        is_active?: boolean | null;       // default: true
        search?: string | null;           // searches name, address, city, description
        sort_by?:
          | 'id' | 'address' | 'city' | 'country' | 'created_at' | 'currency'
          | 'description' | 'email' | 'is_active' | 'latitude' | 'longitude'
          | 'name' | 'owner_id' | 'phone_number' | 'postal_code' | 'qr_code_url'
          | 'slug' | 'state' | 'timezone' | 'updated_at'
          | null;                         // default: 'name'
        sort_direction?: 'asc' | 'ASC' | 'desc' | 'DESC' | null; // default: 'asc'
    DESC
    param :page, Integer, required: false, desc: "Page number (default: 1)"
    param :per_page, Integer, required: false, desc: "Results per page, max 100 (default: 10)"
    param :city, String, required: false, desc: "Filter by city (exact match)"
    param :state, String, required: false, desc: "Filter by state (exact match)"
    param :country, String, required: false, desc: "Filter by country (exact match)"
    param :is_active, :bool, required: false, desc: "Filter by active status (default: true)"
    param :search, String, required: false, desc: "Full-text search across name, address, city, description"
    param :sort_by, %w[name city created_at], required: false, desc: "Sort field (default: name)"
    param :sort_direction, %w[asc desc], required: false, desc: "Sort direction (default: asc)"
    returns code: 200, desc: "List of venues" do
      property :success, [ true ]
      property :data, Array, desc: "Array of venue objects (list view)" do
        property :id, Integer
        property :name, String
        property :slug, String
        property :description, String, required: false
        property :address, String
        property :city, String
        property :state, String
        property :country, String
        property :postal_code, String, required: false
        property :phone_number, String, required: false
        property :email, String, required: false
        property :timezone, String, required: false, description: "default to 'Asia/Karachi'"
        property :currency, String, required: false, description: "default to 'PKR'"
        property :is_active, :bool, required: false, description: "Whether the venue is publicly visible, default: true"
        property :latitude, Float, required: false
        property :longitude, Float, required: false
        property :google_maps_url, String, required: false, description: "if lat/lng are present, a Google Maps link is generated"
        property :courts_count, Integer
        property :created_at, String, desc: "ISO 8601 creation timestamp"
      end
    end
    def search
      result = Api::V0::Venues::SearchVenuesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/venues/:id", "Retrieve a single venue with full details"
    param :id, String, required: true, desc: "Venue ID or slug"
    returns code: 200, desc: "Venue details" do
      property :success, [ true ]
      property :data, Hash, desc: "Venue object (detailed view)" do
        property :id, Integer
        property :name, String
        property :slug, String
        property :description, String, required: false
        property :address, String
        property :city, String
        property :state, String
        property :country, String
        property :postal_code, String, required: false
        property :phone_number, String, required: false
        property :email, String, required: false
        property :timezone, String, required: false, description: "default to 'Asia/Karachi'"
        property :currency, String, required: false, description: "default to 'PKR'"
        property :is_active, :bool, required: false, description: "Whether the venue is publicly visible, default: true"
        property :latitude, Float, required: false
        property :longitude, Float, required: false
        property :google_maps_url, String, required: false, description: "if lat/lng are present, a Google Maps link is generated"
        property :courts_count, Integer
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :venue_operating_hours, Array, desc: "Operating hours for each day of the week" do
          property :id, Integer
          property :venue_id, Integer
          property :day_of_week, Integer, desc: "0 = Monday … 6 = Sunday"
          property :day_name, String, desc: "Full day name (e.g. Monday)"
          property :opens_at, String, desc: "Opening time"
          property :closes_at, String, desc: "Closing time"
          property :formatted_hours, String, desc: "Human-readable range or 'Closed'"
          property :is_closed, :bool
        end
      end
    end
    error code: 404, desc: "Venue not found"
    def show
      result = Api::V0::Venues::GetVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/venues/:id/availability", "Get available time slots for a venue on a given date"
    param :id, Integer, required: true, desc: "Venue ID"
    param :date, String, required: true, desc: "Date to check availability for (YYYY-MM-DD)"
    returns code: 200, desc: "Available slots for each court in the venue"
    error code: 404, desc: "Venue not found"
    def availability
      result = Api::V0::Venues::ListAvailabilityOperation.call(params.to_unsafe_h)

      handle_operation_response(result)
    end

    api :POST, "/venues", "Create a new venue"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Creates a new venue owned by the authenticated user.

      Body Params — TS type

        {
          name: string;                          // required
          address: string;                       // required
          city: string;                          // required
          state: string;                         // required
          country?: string | null;               // default: 'Pakistan'
          description?: string | null;
          postal_code?: string | null;
          phone_number?: string | null;
          email?: string | null;
          latitude?: number | null;
          longitude?: number | null;
          timezone?: string | null;              // default: 'Asia/Karachi'
          currency?: string | null;              // default: 'PKR'
          is_active?: boolean | null;            // default: false
          venue_operating_hours?: Array<{
            day_of_week: number;                 // 0 = Monday … 6 = Sunday, required
            opens_at?: string | null;            // HH:MM — ignored when is_open_24h is true
            closes_at?: string | null;           // HH:MM — ignored when is_open_24h is true
            is_closed?: boolean | null;
            is_open_24h?: boolean | null;        // true = open all day; opens_at/closes_at not required, default: false
          }> | null;
        }
    DESC
    param :name, String, required: true, desc: "Venue name"
    param :address, String, required: true, desc: "Street address"
    param :city, String, required: true, desc: "City"
    param :state, String, required: true, desc: "State / province"
    param :country, String, required: false, desc: "Country, defaults to 'Pakistan'"
    param :description, String, required: false, desc: "Venue description"
    param :postal_code, String, required: false, desc: "Postal / ZIP code"
    param :phone_number, String, required: false, desc: "Contact phone number"
    param :email, String, required: false, desc: "Contact email address"
    param :latitude, Float, required: false, desc: "GPS latitude"
    param :longitude, Float, required: false, desc: "GPS longitude"
    param :timezone, String, required: false, desc: "IANA timezone identifier (e.g. Asia/Karachi)"
    param :currency, String, required: false, desc: "ISO 4217 currency code (e.g. PKR)"
    param :is_active, :bool, required: false, desc: "Whether the venue is publicly visible (default: false)"
    param :venue_operating_hours, Array, desc: "Operating hours per day" do
      param :day_of_week, Integer, required: true, desc: "0 = Monday … 6 = Sunday"
      param :opens_at, String, required: false, desc: "Opening time (HH:MM) — not required when is_open_24h is true"
      param :closes_at, String, required: false, desc: "Closing time (HH:MM) — not required when is_open_24h is true"
      param :is_closed, :bool, required: false, desc: "Mark day as closed"
      param :is_open_24h, :bool, required: false, desc: "Mark day as open 24 hours (opens_at/closes_at not required), default: false"
    end
    returns code: 201, desc: "Venue created" do
      property :success, [ true ]
      property :data, Hash, desc: "Created venue object" do
        property :id, Integer
        property :name, String
        property :slug, String
        property :description, String, required: false
        property :address, String
        property :city, String
        property :state, String
        property :country, String
        property :postal_code, String, required: false
        property :phone_number, String, required: false
        property :email, String, required: false
        property :timezone, String, required: false, description: "default to 'Asia/Karachi'"
        property :currency, String, required: false, description: "default to 'PKR'"
        property :is_active, :bool, required: false, description: "Whether the venue is publicly visible, default: true"
        property :latitude, Float, required: false
        property :longitude, Float, required: false
        property :google_maps_url, String, required: false, description: "if lat/lng are present, a Google Maps link is generated"
        property :courts_count, Integer
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :venue_operating_hours, Array, desc: "Operating hours for each day of the week" do
          property :id, Integer
          property :venue_id, Integer
          property :day_of_week, Integer, desc: "0 = Monday … 6 = Sunday"
          property :day_name, String, desc: "Full day name (e.g. Monday)"
          property :opens_at, String, desc: "Opening time"
          property :closes_at, String, desc: "Closing time"
          property :formatted_hours, String, desc: "Human-readable range or 'Closed'"
          property :is_closed, :bool
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Insufficient permissions (only venue owners / admins)"
    error code: 422, desc: "Validation error"
    def create
      result = Api::V0::Venues::CreateVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    api :PUT, "/venues/:id", "Update an existing venue"
    api :PATCH, "/venues/:id", "Update an existing venue (partial)"
    header "Authorization", "Bearer <access_token>", required: true
    description <<~DESC
      Updates an existing venue. All body fields are optional — only supplied fields are changed.

      Body Params — TS type

        {
          name?: string | null;
          address?: string | null;
          city?: string | null;
          state?: string | null;
          country?: string | null;
          description?: string | null;
          postal_code?: string | null;
          phone_number?: string | null;
          email?: string | null;
          latitude?: number | null;
          longitude?: number | null;
          timezone?: string | null;
          currency?: string | null;
          is_active?: boolean | null;
          venue_operating_hours?: Array<{
            day_of_week: number;                 // 0 = Monday … 6 = Sunday, required
            opens_at?: string | null;            // HH:MM — ignored when is_open_24h is true
            closes_at?: string | null;           // HH:MM — ignored when is_open_24h is true
            is_closed?: boolean | null;
            is_open_24h?: boolean | null;        // true = open all day; opens_at/closes_at not required, default: false
          }> | null;
        }
    DESC
    param :id, Integer, required: true, desc: "Venue ID"
    param :name, String, required: false, desc: "Venue name"
    param :address, String, required: false, desc: "Street address"
    param :city, String, required: false, desc: "City"
    param :state, String, required: false, desc: "State / province"
    param :country, String, required: false, desc: "Country"
    param :description, String, required: false, desc: "Venue description"
    param :postal_code, String, required: false, desc: "Postal / ZIP code"
    param :phone_number, String, required: false, desc: "Contact phone number"
    param :email, String, required: false, desc: "Contact email"
    param :latitude, Float, required: false, desc: "GPS latitude"
    param :longitude, Float, required: false, desc: "GPS longitude"
    param :timezone, String, required: false, desc: "IANA timezone identifier"
    param :currency, String, required: false, desc: "ISO 4217 currency code"
    param :is_active, :bool, required: false, desc: "Publicly visible toggle"
    param :venue_operating_hours, Array, desc: "Operating hours per day", required: false do
      param :day_of_week, Integer, required: true, desc: "0 = Monday … 6 = Sunday"
      param :opens_at, String, required: false, desc: "Opening time (HH:MM) — not required when is_open_24h is true"
      param :closes_at, String, required: false, desc: "Closing time (HH:MM) — not required when is_open_24h is true"
      param :is_closed, :bool, required: false, desc: "Mark day as closed"
      param :is_open_24h, :bool, required: false, desc: "Mark day as open 24 hours (opens_at/closes_at not required), default: false"
    end
    returns code: 200, desc: "Updated venue" do
      property :success, [ true ]
      property :data, Hash, desc: "Created venue object" do
        property :id, Integer
        property :name, String
        property :slug, String
        property :description, String, required: false
        property :address, String
        property :city, String
        property :state, String
        property :country, String
        property :postal_code, String, required: false
        property :phone_number, String, required: false
        property :email, String, required: false
        property :timezone, String, required: false, description: "default to 'Asia/Karachi'"
        property :currency, String, required: false, description: "default to 'PKR'"
        property :is_active, :bool, required: false, description: "Whether the venue is publicly visible, default: true"
        property :latitude, Float, required: false
        property :longitude, Float, required: false
        property :google_maps_url, String, required: false, description: "if lat/lng are present, a Google Maps link is generated"
        property :courts_count, Integer
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :venue_operating_hours, Array, desc: "Operating hours for each day of the week" do
          property :id, Integer
          property :venue_id, Integer
          property :day_of_week, Integer, desc: "0 = Monday … 6 = Sunday"
          property :day_name, String, desc: "Full day name (e.g. Monday)"
          property :opens_at, String, desc: "Opening time"
          property :closes_at, String, desc: "Closing time"
          property :formatted_hours, String, desc: "Human-readable range or 'Closed'"
          property :is_closed, :bool
        end
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue not found"
    error code: 422, desc: "Validation error"
    def update
      result = Api::V0::Venues::UpdateVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :DELETE, "/venues/:id", "Delete a venue"
    header "Authorization", "Bearer <access_token>", required: true
    param :id, Integer, required: true, desc: "Venue ID"
    returns code: 200, desc: "Venue deleted"
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Not the venue owner or insufficient permissions"
    error code: 404, desc: "Venue not found"
    def destroy
      result = Api::V0::Venues::DeleteVenueOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end
  end
end
