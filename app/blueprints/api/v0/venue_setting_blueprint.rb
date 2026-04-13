# frozen_string_literal: true

module Api::V0
  class VenueSettingBlueprint < BaseBlueprint
    identifier :id

    fields :minimum_slot_duration,
           :maximum_slot_duration,
           :slot_interval,
           :advance_booking_days,
           :requires_approval,
           :cancellation_hours,
           :timezone,
           :currency
  end
end
