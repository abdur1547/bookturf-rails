# frozen_string_literal: true

module Api::V0
  class PricingRulesController < ApiController
    resource_description do
      resource_id "Pricing Rules"
      api_versions "v0"
      short "Manage pricing rules for courts — creation, listing, retrieval, updates, and deletion"
      description <<~DESC
        Pricing rules define time-based or date-based pricing overrides for a court.
        Creating, updating, and deleting rules requires the authenticated user to be
        the venue owner or a global admin. Listing and showing rules requires
        authentication with at least venue-staff level access.
      DESC
    end

    api :GET, "/pricing_rules", "List all pricing rules for a specific court"
    description <<~DESC
      Returns all pricing rules for the given court. The authenticated user must have
      at least venue-staff (receptionist) level access to the court's venue.
      Admins can access pricing rules for any court. Results are ordered by priority
      descending, then name ascending.
    DESC
    header "Authorization", "Bearer <access_token>", required: true
    param :court_id, Integer, required: true, desc: "ID of the court whose pricing rules to list"
    param :is_active, :bool, required: false, desc: "Filter by active status; omitting returns all rules"
    param :day_of_week, String, required: false,
          desc: "Filter by day (monday, tuesday, wednesday, thursday, friday, saturday, sunday, all_days, weekdays, weekends)"
    returns code: 200, desc: "Pricing rules retrieved successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Array, desc: "Array of pricing rule objects" do
        property :id, Integer, desc: "Pricing rule ID"
        property :venue_id, Integer, desc: "Parent venue ID"
        property :court_id, Integer, desc: "Parent court ID"
        property :name, String, desc: "Rule name"
        property :price_per_hour, Float, desc: "Price per hour in the venue's currency"
        property :day_of_week, String, desc: "Day applicability (e.g. monday, weekends, all_days)"
        property :start_time, String, desc: "Start time (HH:MM), null for all-day rules"
        property :end_time, String, desc: "End time (HH:MM), null for all-day rules"
        property :start_date, String, desc: "Start date (YYYY-MM-DD), null for permanent rules"
        property :end_date, String, desc: "End date (YYYY-MM-DD), null for permanent rules"
        property :priority, Integer, desc: "Rule priority — higher value wins when multiple rules overlap"
        property :is_active, :bool, desc: "Whether this rule is currently active"
        property :day_name, String, desc: "Human-readable day label (e.g. Monday, All Days)"
        property :time_range, String, desc: "Formatted time window (e.g. 08:00 AM - 12:00 PM) or All day"
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :updated_at, String, desc: "ISO 8601 last-update timestamp"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Insufficient permissions to view pricing rules for this court's venue"
    error code: 404, desc: "Court not found"
    error code: 422, desc: "Validation error — e.g. missing court_id, invalid day_of_week value"
    # GET /api/v0/pricing_rules
    def index
      result = Api::V0::PricingRules::ListPricingRulesOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :GET, "/pricing_rules/:id", "Retrieve a single pricing rule by ID"
    description <<~DESC
      Returns the pricing rule with the given ID. The authenticated user must have
      at least venue-staff (receptionist) level access to the rule's venue, or be a
      global admin. A 403 is returned when the user's role is insufficient; a 404
      when the rule does not exist regardless of permissions.
    DESC
    header "Authorization", "Bearer <access_token>", required: true
    param :id, Integer, required: true, desc: "ID of the pricing rule to retrieve"
    returns code: 200, desc: "Pricing rule retrieved successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Pricing rule object (detailed view)" do
        property :id, Integer, desc: "Pricing rule ID"
        property :venue_id, Integer, desc: "Parent venue ID"
        property :court_id, Integer, desc: "Parent court ID"
        property :name, String, desc: "Rule name"
        property :price_per_hour, Float, desc: "Price per hour in the venue's currency"
        property :day_of_week, String, desc: "Day applicability (e.g. monday, weekends, all_days)"
        property :start_time, String, desc: "Start time (HH:MM), null for all-day rules"
        property :end_time, String, desc: "End time (HH:MM), null for all-day rules"
        property :start_date, String, desc: "Start date (YYYY-MM-DD), null for permanent rules"
        property :end_date, String, desc: "End date (YYYY-MM-DD), null for permanent rules"
        property :priority, Integer, desc: "Rule priority — higher value wins when multiple rules overlap"
        property :is_active, :bool, desc: "Whether this rule is currently active"
        property :day_name, String, desc: "Human-readable day label (e.g. Monday, All Days)"
        property :time_range, String, desc: "Formatted time window (e.g. 08:00 AM - 12:00 PM) or All day"
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :updated_at, String, desc: "ISO 8601 last-update timestamp"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Insufficient permissions to view this pricing rule"
    error code: 404, desc: "Pricing rule not found"
    # GET /api/v0/pricing_rules/:id
    def show
      result = Api::V0::PricingRules::GetPricingRuleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :POST, "/pricing_rules", "Create a new pricing rule for a court"
    description <<~DESC
      Creates a pricing rule tied to a specific court. The authenticated user must be
      the owner of the court's venue or a global admin. The court's venue is resolved
      automatically from the given court_id.

      When start_time and end_time are omitted the rule applies all day.
      When start_date and end_date are omitted the rule applies permanently.
      When day_of_week is omitted the rule defaults to all_days.
      Priority determines precedence when multiple rules overlap — higher value wins.
    DESC
    header "Authorization", "Bearer <access_token>", required: true
    param :name, String, required: true, desc: "Descriptive name for this rule (e.g. Weekend Evening Peak)"
    param :court_id, Integer, required: true, desc: "ID of the court this rule applies to"
    param :price_per_hour, Float, required: true, desc: "Price per hour — must be greater than 0"
    param :day_of_week, String, required: false,
          desc: "Day applicability: monday, tuesday, wednesday, thursday, friday, saturday, sunday, all_days, weekdays, weekends (default: all_days)"
    param :start_time, String, required: false, desc: "Start time in HH:MM format — omit for all-day rules"
    param :end_time, String, required: false, desc: "End time in HH:MM format — must be after start_time"
    param :start_date, String, required: false, desc: "Start date in YYYY-MM-DD format — omit for permanent rules"
    param :end_date, String, required: false, desc: "End date in YYYY-MM-DD format — must be on or after start_date"
    param :priority, Integer, required: false, desc: "Rule priority (default: 0) — higher value wins when rules overlap"
    param :is_active, :bool, required: false, desc: "Whether this rule is active immediately (default: true)"
    returns code: 201, desc: "Pricing rule created successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Created pricing rule object" do
        property :id, Integer, desc: "Pricing rule ID"
        property :venue_id, Integer, desc: "Parent venue ID (resolved from court)"
        property :court_id, Integer, desc: "Parent court ID"
        property :name, String, desc: "Rule name"
        property :price_per_hour, Float, desc: "Price per hour in the venue's currency"
        property :day_of_week, String, desc: "Day applicability (e.g. monday, weekends, all_days)"
        property :start_time, String, desc: "Start time string, null if not set"
        property :end_time, String, desc: "End time string, null if not set"
        property :start_date, String, desc: "Start date string (YYYY-MM-DD), null if not set"
        property :end_date, String, desc: "End date string (YYYY-MM-DD), null if not set"
        property :priority, Integer, desc: "Rule priority"
        property :is_active, :bool, desc: "Whether this rule is currently active"
        property :day_name, String, desc: "Human-readable day label (e.g. Monday, All Days)"
        property :time_range, String, desc: "Formatted time window (e.g. 08:00 AM - 12:00 PM) or All day"
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :updated_at, String, desc: "ISO 8601 last-update timestamp"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user is not the venue owner or a global admin"
    error code: 404, desc: "Court not found"
    error code: 422, desc: "Validation error — e.g. blank name, price ≤ 0, end_time before start_time, end_date before start_date, invalid day_of_week"
    # POST /api/v0/pricing_rules
    def create
      result = Api::V0::PricingRules::CreatePricingRuleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result, :created)
    end

    api :PATCH, "/pricing_rules/:id", "Update an existing pricing rule"
    api :PUT, "/pricing_rules/:id", "Update an existing pricing rule"
    description <<~DESC
      Updates a pricing rule by ID. The authenticated user must be the owner of the
      rule's venue or a global admin. Only the fields provided in the request are
      updated — omitting a field leaves its current value unchanged.

      Only start_time and end_time, or start_date and end_date, may be cleared together.
      Partial time or date pairs are validated the same way as on creation.
    DESC
    header "Authorization", "Bearer <access_token>", required: true
    param :id, Integer, required: true, desc: "ID of the pricing rule to update"
    param :name, String, required: false, desc: "Rule name"
    param :price_per_hour, Float, required: false, desc: "Price per hour — must be greater than 0"
    param :day_of_week, String, required: false,
          desc: "Day applicability: monday, tuesday, wednesday, thursday, friday, saturday, sunday, all_days, weekdays, weekends"
    param :start_time, String, required: false, desc: "Start time in HH:MM format"
    param :end_time, String, required: false, desc: "End time in HH:MM format — must be after start_time"
    param :start_date, String, required: false, desc: "Start date in YYYY-MM-DD format"
    param :end_date, String, required: false, desc: "End date in YYYY-MM-DD format — must be on or after start_date"
    param :priority, Integer, required: false, desc: "Rule priority — higher value wins when rules overlap"
    param :is_active, :bool, required: false, desc: "Whether this rule is active"
    returns code: 200, desc: "Pricing rule updated successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :data, Hash, desc: "Updated pricing rule object" do
        property :id, Integer, desc: "Pricing rule ID"
        property :venue_id, Integer, desc: "Parent venue ID"
        property :court_id, Integer, desc: "Parent court ID"
        property :name, String, desc: "Rule name"
        property :price_per_hour, Float, desc: "Price per hour"
        property :day_of_week, String, desc: "Day applicability"
        property :start_time, String, desc: "Start time string, null if not set"
        property :end_time, String, desc: "End time string, null if not set"
        property :start_date, String, desc: "Start date string, null if not set"
        property :end_date, String, desc: "End date string, null if not set"
        property :priority, Integer, desc: "Rule priority"
        property :is_active, :bool, desc: "Whether this rule is currently active"
        property :day_name, String, desc: "Human-readable day label"
        property :time_range, String, desc: "Formatted time window or All day"
        property :created_at, String, desc: "ISO 8601 creation timestamp"
        property :updated_at, String, desc: "ISO 8601 last-update timestamp"
      end
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user is not the venue owner or a global admin"
    error code: 404, desc: "Pricing rule not found"
    error code: 422, desc: "Validation error — e.g. price ≤ 0, end_time before start_time, invalid day_of_week"
    # PATCH/PUT /api/v0/pricing_rules/:id
    def update
      result = Api::V0::PricingRules::UpdatePricingRuleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end

    api :DELETE, "/pricing_rules/:id", "Delete a pricing rule by ID"
    header "Authorization", "Bearer <access_token>", required: true
    param :id, Integer, required: true, desc: "ID of the pricing rule to delete"
    returns code: 200, desc: "Pricing rule deleted successfully" do
      property :success, [ true ], desc: "Always true on success"
      property :message, String, desc: "Confirmation message"
    end
    error code: 401, desc: "Not authenticated"
    error code: 403, desc: "Authenticated user is not the venue owner or a global admin"
    error code: 404, desc: "Pricing rule not found"
    # DELETE /api/v0/pricing_rules/:id
    def destroy
      result = Api::V0::PricingRules::DeletePricingRuleOperation.call(params.to_unsafe_h, current_user)

      handle_operation_response(result)
    end
  end
end
