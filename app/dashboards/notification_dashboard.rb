require "administrate/base_dashboard"

class NotificationDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    user: Field::BelongsTo,
    venue: Field::BelongsTo,
    booking: Field::BelongsTo,
    title: Field::String,
    message: Field::Text,
    notification_type: Field::String,
    priority: Field::String,
    is_read: Field::Boolean,
    read_at: Field::DateTime,
    sent_at: Field::DateTime,
    action_url: Field::String,
    created_at: Field::DateTime,
    updated_at: Field::DateTime
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    user
    title
    notification_type
    is_read
    sent_at
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    user
    venue
    booking
    title
    message
    notification_type
    priority
    is_read
    read_at
    sent_at
    action_url
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    venue
    booking
    title
    message
    notification_type
    priority
    action_url
  ].freeze

  COLLECTION_FILTERS = {
    unread: ->(resources) { resources.where(is_read: false) }
  }.freeze

  def display_resource(notification)
    notification.title
  end
end
