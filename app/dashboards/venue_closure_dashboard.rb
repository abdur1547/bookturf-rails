require "administrate/base_dashboard"

class VenueClosureDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    venue: Field::BelongsTo,
    title: Field::String,
    description: Field::Text,
    start_time: Field::DateTime,
    end_time: Field::DateTime,
    created_by: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    venue
    title
    start_time
    end_time
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    venue
    title
    description
    start_time
    end_time
    created_by
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    venue
    title
    description
    start_time
    end_time
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(vc)
    "#{vc.venue&.name} – #{vc.title}"
  end
end
