# frozen_string_literal: true

module Venues
  class VenueDestroyerService < BaseService
    def call(venue:)
      ActiveRecord::Base.transaction do
        # Check for dependencies
        if venue.courts.exists?
          return failure("Cannot delete venue with existing courts")
        end

        if venue.bookings.exists?
          return failure("Cannot delete venue with existing bookings")
        end

        unless venue.destroy
          return failure(venue.errors.full_messages)
        end

        success(true)
      end
    rescue StandardError => e
      failure("Failed to delete venue: #{e.message}")
    end
  end
end
