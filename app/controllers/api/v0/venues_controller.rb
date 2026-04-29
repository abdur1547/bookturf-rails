# frozen_string_literal: true

module Api::V0
  class VenuesController < ApiController
    skip_before_action :authenticate_user!, only: [ :index, :show, :availability ]

    resource_description do
      resource_id "Venues"
      api_versions "v0"
      short "Manage sports venues — listing, creation, updates, availability, and onboarding"
      description <<~DESC
        Venues are the core resource of Bookturf. A venue owner can create and manage venues,
        including their courts, operating hours, and onboarding progress.
        Public endpoints (index, show, availability) do not require authentication.
      DESC
    end

    api :GET, "/venues", "List all active venues"
    description "Returns a paginated list of venues. Defaults to active venues only."
    param :page, Integer, required: false, desc: "Page number (default: 1)"
    param :per_page, Integer, required: false, desc: "Results per page, max 100 (default: 10)"
    param :city, String, required: false, desc: "Filter by city (exact match)"
    param :state, String, required: false, desc: "Filter by state (exact match)"
    param :country, String, required: false, desc: "Filter by country (exact match)"
    param :is_active, :bool, required: false, desc: "Filter by active status (default: true)"
    param :search, String, required: false, desc: "Full-text search across name, address, city, description"
    param :sort, %w[name city created_at], required: false, desc: "Sort field (default: name)"
    param :order, %w[asc desc], required: false, desc: "Sort direction (default: asc)"
    returns code: 200, desc: "List of venues" do
      property :success, [ true ]
      property :data, Array, desc: "Array of venue objects (list view)"
    end
    def index
      result = Api::V0::Venues::ListVenuesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/venues/:id", "Retrieve a single venue with full details"
    param :id, Integer, required: true, desc: "Venue ID"
    returns code: 200, desc: "Venue details" do
      property :success, [ true ]
      property :data, Hash, desc: "Venue object (detailed view) including owner, courts count, and operating hours"
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
    param :name, String, required: true, desc: "Venue name"
    param :address, String, required: true, desc: "Street address"
    param :city, String, required: true, desc: "City"
    param :state, String, required: true, desc: "State / province"
    param :country, String, required: true, desc: "Country"
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
      param :opens_at, String, required: false, desc: "Opening time (HH:MM)"
      param :closes_at, String, required: false, desc: "Closing time (HH:MM)"
      param :is_closed, :bool, required: false, desc: "Mark day as closed"
    end
    returns code: 201, desc: "Venue created" do
      property :success, [ true ]
      property :data, Hash, desc: "Created venue object" do
        property :id, Integer, desc: "Venue ID"
        property :name, String, desc: "Venue name"
        property :slug, String, desc: "URL-friendly identifier"
        property :address, String, desc: "Street address"
        property :city, String, desc: "City"
        property :state, String, desc: "State / province"
        property :country, String, desc: "Country"
        property :postal_code, String, desc: "Postal / ZIP code"
        property :description, String, desc: "Venue description"
        property :phone_number, String, desc: "Contact phone number"
        property :email, String, desc: "Contact email"
        property :latitude, Float, desc: "GPS latitude"
        property :longitude, Float, desc: "GPS longitude"
        property :google_maps_url, String, desc: "Google Maps link derived from lat/lng"
        property :timezone, String, desc: "IANA timezone identifier"
        property :currency, String, desc: "ISO 4217 currency code"
        property :is_active, :bool, desc: "Whether the venue is publicly visible"
        property :courts_count, Integer, desc: "Number of courts at this venue"
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :updated_at, String, desc: "ISO 8601 last-update timestamp"
        property :owner, Hash, desc: "Venue owner user object" do
          property :id, Integer
          property :email, String
          property :full_name, String
          property :phone_number, String
          property :user_type, String
          property :avatar_url, String
          property :owner_data, Hash
          property :staff_data, Hash
          property :preferences, Hash, desc: "Notification and location preferences" do
            property :preferred_city, String
            property :preferred_town, String
            property :notification_reminders, :bool
            property :notification_30min, :bool
          end
          property :created_at, String
          property :updated_at, String
        end
        property :venue_operating_hours, Array, desc: "Operating hours for each day of the week" do
          property :id, Integer
          property :venue_id, Integer
          property :day_of_week, Integer, desc: "0 = Monday … 6 = Sunday"
          property :day_name, String, desc: "Full day name (e.g. Monday)"
          property :opens_at, String, desc: "ISO 8601 open time"
          property :closes_at, String, desc: "ISO 8601 close time"
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
      param :opens_at, String, required: false, desc: "Opening time (HH:MM)"
      param :closes_at, String, required: false, desc: "Closing time (HH:MM)"
      param :is_closed, :bool, required: false, desc: "Mark day as closed"
    end
    returns code: 200, desc: "Updated venue" do
      property :success, [ true ]
      property :data, Hash, desc: "Updated venue object (detailed view)"
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
