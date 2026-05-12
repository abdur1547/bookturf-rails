require "administrate/base_dashboard"

class BookingDashboard < Administrate::BaseDashboard
  ATTRIBUTE_TYPES = {
    id: Field::Number,
    booking_number: Field::String,
    user: Field::BelongsTo,
    venue: Field::BelongsTo,
    court: Field::BelongsTo,
    start_time: Field::DateTime,
    end_time: Field::DateTime,
    duration_minutes: Field::Number,
    status: Field::Select.with_options(
      searchable: false,
      collection: Booking::STATUSES
    ),
    payment_status: Field::Select.with_options(
      searchable: false,
      collection: Booking::PAYMENT_STATUSES
    ),
    payment_method: Field::Select.with_options(
      searchable: false,
      collection: Booking::PAYMENT_METHODS
    ),
    total_amount: Field::String.with_options(searchable: false),
    paid_amount: Field::String.with_options(searchable: false),
    price_at_booking: Field::String.with_options(searchable: false),
    walk_in_name: Field::String,
    created_by: Field::BelongsTo,
    created_by_role: Field::String,
    checked_in_at: Field::DateTime,
    checked_in_by: Field::BelongsTo,
    cancelled_at: Field::DateTime,
    cancelled_by: Field::BelongsTo,
    cancellation_reason: Field::Text,
    notes: Field::Text,
    share_token: Field::String,
    deferred_link_claimed: Field::Boolean,
    notifications: Field::HasMany,
    created_at: Field::DateTime,
    updated_at: Field::DateTime,
  }.freeze

  COLLECTION_ATTRIBUTES = %i[
    booking_number
    user
    court
    status
    start_time
    payment_status
  ].freeze

  SHOW_PAGE_ATTRIBUTES = %i[
    id
    booking_number
    user
    venue
    court
    start_time
    end_time
    duration_minutes
    status
    payment_status
    payment_method
    total_amount
    paid_amount
    price_at_booking
    walk_in_name
    created_by
    created_by_role
    checked_in_at
    checked_in_by
    cancelled_at
    cancelled_by
    cancellation_reason
    notes
    share_token
    deferred_link_claimed
    notifications
    created_at
    updated_at
  ].freeze

  FORM_ATTRIBUTES = %i[
    user
    venue
    court
    start_time
    end_time
    status
    payment_status
    payment_method
    walk_in_name
    notes
  ].freeze

  COLLECTION_FILTERS = {
    confirmed: ->(resources) { resources.confirmed },
    cancelled: ->(resources) { resources.cancelled },
    today: ->(resources) { resources.today },
  }.freeze

  def display_resource(booking)
    booking.booking_number
  end
end
