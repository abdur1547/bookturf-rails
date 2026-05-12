require "administrate/base_dashboard"

class RoleDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    venue: Field::BelongsTo,
    role_permissions: Field::HasMany,
    venue_memberships: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    venue
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    venue
    role_permissions
    venue_memberships
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    venue
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(role)
    role.name
  end
end
