require "administrate/base_dashboard"

class VenueDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    owner: Field::BelongsTo,
    address: Field::Text,
    city: Field::String,
    state: Field::String,
    country: Field::String,
    postal_code: Field::String,
    phone_number: Field::String,
    email: Field::String,
    timezone: Field::String,
    currency: Field::String,
    latitude: Field::String.with_options(searchable: false),
    longitude: Field::String.with_options(searchable: false),
    is_active: Field::Boolean,
    description: Field::Text,
    qr_code_url: Field::String,
    courts: Field::HasMany,
    bookings: Field::HasMany,
    venue_operating_hours: Field::HasMany,
    venue_closures: Field::HasMany,
    venue_memberships: Field::HasMany,
    roles: Field::HasMany,
    pricing_rules: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    owner
    city
    country
    is_active
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    owner
    address
    city
    state
    country
    postal_code
    phone_number
    email
    timezone
    currency
    latitude
    longitude
    is_active
    description
    courts
    bookings
    venue_operating_hours
    venue_closures
    venue_memberships
    roles
    pricing_rules
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    owner
    address
    city
    state
    country
    postal_code
    phone_number
    email
    timezone
    currency
    latitude
    longitude
    is_active
    description
  ].freeze

  COLLECTION_FILTERS = {
    active: ->(resources) { resources.active },
    inactive: ->(resources) { resources.inactive },
  }.freeze

  def display_resource(venue)
    venue.name
  end
end
