require "administrate/base_dashboard"

class VenueOperatingHourDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    venue: Field::BelongsTo,
    day_of_week: Field::Number,
    opens_at: Field::Time,
    closes_at: Field::Time,
    is_closed: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    venue
    day_of_week
    opens_at
    closes_at
    is_closed
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    venue
    day_of_week
    opens_at
    closes_at
    is_closed
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    venue
    day_of_week
    opens_at
    closes_at
    is_closed
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(oh)
    "#{oh.venue&.name} – day #{oh.day_of_week}"
  end
end
