require "administrate/base_dashboard"

class PricingRuleDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    name: Field::String,
    venue: Field::BelongsTo,
    court: Field::BelongsTo,
    price_per_hour: Field::String.with_options(searchable: false),
    day_of_week: Field::Select.with_options(
      searchable: false,
      collection: ->(field) { field.resource.class.send(field.attribute.to_s.pluralize).keys }
    ),
    start_time: Field::Time,
    end_time: Field::Time,
    start_date: Field::Date,
    end_date: Field::Date,
    priority: Field::Number,
    is_active: Field::Boolean,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    name
    venue
    court
    price_per_hour
    is_active
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    name
    venue
    court
    price_per_hour
    day_of_week
    start_time
    end_time
    start_date
    end_date
    priority
    is_active
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    name
    venue
    court
    price_per_hour
    day_of_week
    start_time
    end_time
    start_date
    end_date
    priority
    is_active
  ].freeze

  COLLECTION_FILTERS = {
    active: ->(resources) { resources.where(is_active: true) }
  }.freeze

  def display_resource(pricing_rule)
    pricing_rule.name
  end
end
