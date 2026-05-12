require "administrate/base_dashboard"

class VenueMembershipDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    user: Field::BelongsTo,
    venue: Field::BelongsTo,
    role: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    user
    venue
    role
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    venue
    role
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    venue
    role
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(vm)
    "#{vm.user&.full_name} @ #{vm.venue&.name}"
  end
end
