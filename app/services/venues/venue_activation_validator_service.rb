# frozen_string_literal: true

module Venues
  class VenueActivationValidatorService < BaseService
    def call(venue:, is_active:)
      # If deactivating, check for active bookings
      if is_active == false || is_active == "false"
        if venue.bookings.where(status: [ :pending, :confirmed ]).exists?
          return failure("Cannot deactivate venue with active bookings")
        end
      end

      # If activating, ensure lat/lng are present
      if is_active == true || is_active == "true"
        if venue.latitude.blank? || venue.longitude.blank?
          return failure("Latitude and longitude are required to activate venue")
        end
      end

      success(true)
    end
  end
end
