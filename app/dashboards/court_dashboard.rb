require "administrate/base_dashboard"

class CourtDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    venue: Field::BelongsTo,
    court_type: Field::BelongsTo,
    description: Field::Text,
    slot_interval: Field::Number,
    requires_approval: Field::Boolean,
    is_active: Field::Boolean,
    qr_code_url: Field::String,
    bookings: Field::HasMany,
    court_closures: Field::HasMany,
    pricing_rules: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    venue
    court_type
    is_active
    requires_approval
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    venue
    court_type
    description
    slot_interval
    requires_approval
    is_active
    bookings
    court_closures
    pricing_rules
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    venue
    court_type
    description
    slot_interval
    requires_approval
    is_active
  ].freeze

  COLLECTION_FILTERS = {
    active: ->(resources) { resources.where(is_active: true) },
  }.freeze

  def display_resource(court)
    court.name
  end
end
