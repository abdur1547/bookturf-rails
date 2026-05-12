require "administrate/base_dashboard"

class CourtTypeDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    slug: Field::String,
    icon: Field::String,
    description: Field::Text,
    courts: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    icon
    slug
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    slug
    icon
    description
    courts
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    slug
    icon
    description
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(court_type)
    court_type.name
  end
end
