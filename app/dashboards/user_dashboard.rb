require "administrate/base_dashboard"

class UserDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    full_name: Field::String,
    email: Field::String,
    phone_number: Field::String,
    system_role: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }
    ),
    is_active: Field::Boolean,
    avatar_url: Field::String,
    provider: Field::String,
    emergency_contact_name: Field::String,
    emergency_contact_phone: Field::String,
    owned_venues: Field::HasMany,
    venues: Field::HasMany,
    bookings: Field::HasMany,
    venue_memberships: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    full_name
    email
    system_role
    is_active
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    full_name
    email
    phone_number
    system_role
    is_active
    provider
    avatar_url
    emergency_contact_name
    emergency_contact_phone
    owned_venues
    venues
    bookings
    venue_memberships
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    full_name
    email
    phone_number
    system_role
    is_active
    avatar_url
    emergency_contact_name
    emergency_contact_phone
  ].freeze

  COLLECTION_FILTERS = {
    active: ->(resources) { resources.active },
    super_admins: ->(resources) { resources.super_admins }
  }.freeze

  def display_resource(user)
    "#{user.full_name} (#{user.email})"
  end
end
