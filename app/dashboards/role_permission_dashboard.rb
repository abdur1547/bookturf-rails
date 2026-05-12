require "administrate/base_dashboard"

class RolePermissionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    role: Field::BelongsTo,
    permission: Field::BelongsTo,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    role
    permission
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    role
    permission
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    role
    permission
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(rp)
    "#{rp.role&.name} → #{rp.permission&.resource}:#{rp.permission&.action}"
  end
end
