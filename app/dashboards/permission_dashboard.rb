require "administrate/base_dashboard"

class PermissionDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    resource: Field::String,
    action: Field::String,
    role_permissions: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    resource
    action
    created_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    resource
    action
    role_permissions
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    resource
    action
  ].freeze

  COLLECTION_FILTERS = {}.freeze

  def display_resource(permission)
    "#{permission.resource}:#{permission.action}"
  end
end
